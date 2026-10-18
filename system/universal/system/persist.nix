_: {
  # `persist.directories` / `persist.files`: what a module needs to survive the
  # root wipe, declared next to the service that needs it, e.g.
  #   persist.directories = [ "/var/lib/netbird" ];
  # Declared on every host (flake.nix adds this module to all of them), so a
  # module can set it unconditionally; it only takes effect on hosts that also
  # import `persist`. Entries use impermanence's format: a path string, or
  # { directory = …; user = …; group = …; mode = …; }.
  flake.nixosModules.persistOptions =
    { lib, ... }:
    let
      entries =
        what:
        lib.mkOption {
          type = with lib.types; listOf (either str (attrsOf anything));
          default = [ ];
          description = "System ${what} to keep across the root wipe (only on hosts importing `persist`).";
        };
    in
    {
      options.persist = {
        directories = entries "directories";
        files = entries "files";
        wipeHome = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Also wipe /home on every boot ("erase your darlings" for ~), keeping
            the previous one in old_homes for 30 days. Only what the users'
            home persistence lists survives. Needs `persist` and home
            persistence enabled for every home-manager user (asserted).
          '';
        };
      };
    };

  flake.nixosModules.persist =
    {
      inputs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.impermanence.nixosModules.impermanence
        # Refuse to wipe a home that has no persistence list.
        # (In a nested module: `options` may only decide the shape of `config`.)
        (
          { options, ... }:
          {
            config = lib.optionalAttrs (options ? home-manager) {
              assertions = lib.mapAttrsToList (name: user: {
                assertion =
                  config.persist.wipeHome -> lib.any (root: root.enable) (lib.attrValues user.home.persistence);
                message = "persist.wipeHome would wipe ${name}'s home, but it has no home persistence enabled (import homeModules.persist in its profile).";
              }) config.home-manager.users;
            };
          }
        )
      ];

      programs.fuse.userAllowOther = true;

      # system files we want to keep
      fileSystems."/persist".neededForBoot = true;

      # Only what every persisted host needs; service-specific state is
      # declared by its own module through `persist.directories`.
      environment.persistence."/persist/system" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/etc/sudoers.d"
          "/var/db/sudo"
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/private"
        ]
        ++ lib.optional config.services.colord.enable {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
        ++ config.persist.directories;
        files = [
          "/var/lib/systemd/credential.secret"
          "/etc/machine-id"
        ]
        # Only sshd's host keys, not all of /etc/ssh: NixOS links sshd_config
        # and ssh_config into /etc/ssh at boot, and a persisted /etc/ssh mounted
        # over them would hide them (sshd then fails on a fresh install).
        ++ lib.optionals config.services.openssh.enable (
          lib.concatMap (key: [
            key.path
            "${key.path}.pub"
          ]) config.services.openssh.hostKeys
        )
        ++ config.persist.files;
      };

      boot.initrd.systemd.services.wipe-root = {
        description = "Wipe the root (and, with persist.wipeHome, home) BTRFS subvolumes";
        wantedBy = [ "initrd.target" ];
        after = [
          "initrd-root-device.target"
          "systemd-hibernate-resume.service"
        ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          mkdir -p /btrfs_tmp
          mount /dev/root_vg/root /btrfs_tmp

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          # Move subvolume $1 to $2/<its last-modified time>, drop entries of
          # $2 older than 30 days, and start $1 empty.
          wipe() {
              if [[ -e "/btrfs_tmp/$1" ]]; then
                  mkdir -p "/btrfs_tmp/$2"
                  timestamp=$(date --date="@$(stat -c %Y "/btrfs_tmp/$1")" "+%Y-%m-%-d_%H:%M:%S")
                  mv "/btrfs_tmp/$1" "/btrfs_tmp/$2/$timestamp"
              fi
              for i in $(find "/btrfs_tmp/$2/" -maxdepth 1 -mindepth 1 -mtime +30 2>/dev/null); do
                  delete_subvolume_recursively "$i"
              done
              btrfs subvolume create "/btrfs_tmp/$1"
          }

          wipe root old_roots
          ${lib.optionalString config.persist.wipeHome "wipe home old_homes"}

          umount /btrfs_tmp
        '';
      };
    };
}

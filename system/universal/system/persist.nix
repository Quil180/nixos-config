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
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      programs.fuse.userAllowOther = true;

      # system files we want to keep
      fileSystems."/persist".neededForBoot = true;

      # Only what every persisted host needs; service-specific state is
      # declared by its own module through `persist.directories`.
      environment.persistence."/persist/system" = {
        hideMounts = true;
        directories = [
          "/etc/nixos"
          "/etc/ssh"
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
        ++ config.persist.files;
      };

      boot.initrd.systemd.services.wipe-root = {
        description = "Wipe Root BTRFS Subvolume";
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

          # Wipe /root
          if [[ -e /btrfs_tmp/root ]]; then
              mkdir -p /btrfs_tmp/old_roots
              timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
              mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
          fi

          delete_subvolume_recursively() {
              IFS=$'\n'
              for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                  delete_subvolume_recursively "/btrfs_tmp/$i"
              done
              btrfs subvolume delete "$1"
          }

          # Clean up old roots older than 30 days
          for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
              delete_subvolume_recursively "$i"
          done

          btrfs subvolume create /btrfs_tmp/root
          umount /btrfs_tmp
        '';
      };
    };
}

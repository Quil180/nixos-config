{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.persist = 
{ lib, ... }:
{
  programs.fuse.userAllowOther = true;

  # system files we want to keep
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/etc/determinate"
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      "/etc/sudoers.d"
      "/var/db/sudo"
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/NetworkManager"
      "/var/lib/systemd/coredump"
      "/var/lib/libvirt"
      "/var/lib/logmein-hamachi"
      "/var/lib/ollama"
      "/var/lib/private"
      "/var/lib/llama-cpp"
      # "/var/lib/private"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    files = [
      "/var/lib/systemd/credential.secret"
      "/etc/machine-id"
    ];
  };

  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe Root BTRFS Subvolume";
    wantedBy = [ "initrd.target" ];
    after = [ "initrd-root-device.target" ];
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
}
;
}

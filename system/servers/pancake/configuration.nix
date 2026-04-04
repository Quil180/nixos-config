{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "pancake";

  services.immich = {
    enable = true;
    # Immich configuration
  };

  # NAS Mount for photos
  fileSystems."/mnt/photos" = {
    device = "breadbox:/mnt/photos";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 2283 ]; # Immich port
}

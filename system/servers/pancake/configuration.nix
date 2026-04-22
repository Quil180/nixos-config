{ topConfig, lib, pkgs, ... }:
{
  configurations.nixos.pancake.module = 
{ pkgs, ... }:
{
  imports = [ topConfig.flake.nixosModules.server_base topConfig.flake.nixosModules.proxmox_vm ];

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
;
}

{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "croissant";

  services.prowlarr.enable = true;
  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.bazarr.enable = true;

  # BitTorrent client
  services.qbittorrent.enable = true;

  # NAS Mount for media
  fileSystems."/mnt/media" = {
    device = "breadbox:/mnt/media";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };

  networking.firewall.allowedTCPPorts = [ 
    9696 # Prowlarr
    8989 # Sonarr
    7878 # Radarr
    6767 # Bazarr
    8080 # qBittorrent WebUI
  ];
}

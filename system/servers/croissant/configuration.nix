{ pkgs, config, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "croissant";

  # 1. NixOS Native Acquisition Stack
  services.prowlarr.enable = true;
  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.bazarr.enable = true;

  # 2. qBittorrent Native
  services.qbittorrent = {
    enable = true;
  };

  age.secrets.vpn_wg_key.file = ../../../secrets/vpn_wg_key.age;

  # 3. WireGuard VPN Client setup (wg0)
  # The user will need to provide their WireGuard credentials via agenix or similar.
  # For now, we set up the interface with placeholders.
  networking.wg-quick.interfaces.wg0 = {
    autostart = true;
    # configFile = config.age.secrets.vpn_wg.path; # Example: use agenix for secrets
    address = [ "10.0.0.2/32" ]; # Replace with your VPN address
    dns = [ "1.1.1.1" ];
    privateKeyFile = config.age.secrets.vpn_wg_key.path;
    peers = [
      {
        publicKey = "REPLACE_WITH_VPN_PUBLIC_KEY";
        endpoint = "REPLACE_WITH_VPN_ENDPOINT:51820";
        allowedIPs = [ "0.0.0.0/0" ];
        persistentKeepalive = 25;
      }
    ];
  };

  # 4. VPN Kill-switch for qBittorrent
  # This uses nftables to restrict the 'qbittorrent' user to ONLY use 'wg0'
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet vpn_killswitch {
        chain output {
          type filter hook output priority filter; policy accept;
          
          # Allow qbittorrent user to talk on loopback (WebUI access)
          skuid qbittorrent oif lo accept
          
          # Allow qbittorrent user to talk on the VPN interface
          skuid qbittorrent oif wg0 accept
          
          # DROP all other traffic for the qbittorrent user
          skuid qbittorrent drop
        }
      }
    '';
  };

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

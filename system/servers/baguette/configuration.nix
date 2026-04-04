{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "baguette";

  services.rustdesk-server = {
    enable = true;
    # HBBS/HBBR ports
    signal.enable = true;
    relay.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
  networking.firewall.allowedUDPPorts = [ 21116 ];
}

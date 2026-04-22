{ topConfig, lib, pkgs, ... }:
{
  configurations.nixos.baguette.module = 
{ pkgs, ... }:
{
  imports = [ topConfig.flake.nixosModules.server_base topConfig.flake.nixosModules.proxmox_vm ];

  networking.hostName = "baguette";

  age.secrets.rustdesk_key.file = ../../../secrets/rustdesk_key.age;

  services.rustdesk-server = {
    enable = true;
    # HBBS/HBBR ports
    signal.enable = true;
    relay.enable = true;
    # keyFile = config.age.secrets.rustdesk_key.path; # Example usage if supported
  };

  networking.firewall.allowedTCPPorts = [
    21115
    21116
    21117
    21118
    21119
  ];
  networking.firewall.allowedUDPPorts = [ 21116 ];
}
;
}

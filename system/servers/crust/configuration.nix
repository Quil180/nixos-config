{ topConfig, lib, pkgs, ... }:
{
  configurations.nixos.crust.module = 
{ pkgs, ... }:
{
  imports = [ topConfig.flake.nixosModules.server_base topConfig.flake.nixosModules.proxmox_vm ];

  networking.hostName = "crust";

  services.caddy = {
    enable = true;
    # Config to be added as needed
  };

  age.secrets.netbird_key.file = ../../../secrets/netbird_key.age;

  # NetBird configuration (assuming netbird package is available)
  environment.systemPackages = with pkgs; [ netbird ];
  services.netbird.enable = true;
  # services.netbird.tokenFile = config.age.secrets.netbird_key.path; # Example usage if supported by the module

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
;
}

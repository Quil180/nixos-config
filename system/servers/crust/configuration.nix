{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "crust";

  services.caddy = {
    enable = true;
    # Config to be added as needed
  };

  # NetBird configuration (assuming netbird package is available)
  environment.systemPackages = with pkgs; [ netbird ];
  services.netbird.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}

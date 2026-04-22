{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.tailscale = 
{pkgs, ...}: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
;
}

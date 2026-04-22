{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.cinnamon = 
{ pkgs, ... }:
{
  # Enable Cinnamon desktop environment
  services.xserver = {
    enable = true;
    desktopManager.cinnamon.enable = true;
  };

  # Cinnamon default apps and utilities
  services.cinnamon.apps.enable = true;

  # Disable power-profiles-daemon since it conflicts with auto-cpufreq
  services.power-profiles-daemon.enable = false;

  # Polkit for privilege escalation prompts
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    cinnamon-common
    nemo # Cinnamon's file manager
  ];
}
;
}

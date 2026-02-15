{ pkgs, ... }:
{
  # Enable Cinnamon desktop environment
  services.xserver = {
    enable = true;
    desktopManager.cinnamon.enable = true;
  };

  # Cinnamon default apps and utilities
  services.cinnamon.apps.enable = true;

  # Polkit for privilege escalation prompts
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    cinnamon-common
    nemo # Cinnamon's file manager
  ];
}

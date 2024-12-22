{ config, lib, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    sddm
    hyprland
  ];

  fonts.packages = with pkgs; [
    iosevka
  ];

  programs.hyprland = true;

  services = {
    xserver.enable = true;

    # setting sddm as default login screen
    displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      autoNumlock = true;
    };
  };
}

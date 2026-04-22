{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.rofi = 
{...}: {
  programs.rofi = {
    enable = true;
  };
}
;
}

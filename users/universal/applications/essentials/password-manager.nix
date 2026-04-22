{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.password-manager = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    bitwarden-desktop
  ];
}
;
}

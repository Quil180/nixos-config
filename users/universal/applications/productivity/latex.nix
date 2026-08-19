{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.latex = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    texliveFull
    zathura # for pdf viewing
  ];
}
;
}

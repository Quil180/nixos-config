{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.latex = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    texliveSmall
    zathura # for pdf viewing
  ];
}
;
}

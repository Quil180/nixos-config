{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.latex = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    texlive.combined.scheme-full
		zathura # for pdf viewing
  ];
}
;
}

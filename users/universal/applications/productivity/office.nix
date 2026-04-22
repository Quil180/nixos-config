{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.office = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    libreoffice-qt6
    hunspell
    hunspellDicts.en_US

    corefonts
    vista-fonts
  ];
}
;
}

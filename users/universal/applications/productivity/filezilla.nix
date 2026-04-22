{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.filezilla = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    filezilla
  ];
}
;
}

{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.vivaldi = 
{pkgs, ...}:
{
  home.packages = with pkgs; [
    vivaldi
  ];
}
;
}

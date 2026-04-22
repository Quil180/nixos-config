{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.cpp = 
{ pkgs, ... }: {
  home.packages = with pkgs; [
    gcc
    cmake
  ];
}
;
}

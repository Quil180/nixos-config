{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.vncviewer = 
{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    realvnc-vnc-viewer
  ];
}
;
}

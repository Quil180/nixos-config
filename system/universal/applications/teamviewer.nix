{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.teamviewer = 
{...}:
{
	services.teamviewer.enable = true;
}
;
}

{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.kicad = 
{pkgs, ...}:
{
	home.packages = with pkgs; [
		kicad
	];
}
;
}

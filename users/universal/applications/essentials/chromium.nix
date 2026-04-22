{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.chromium = 
{pkgs, ...}:
{
	home.packages = with pkgs; [
		chromium
	];
}
;
}

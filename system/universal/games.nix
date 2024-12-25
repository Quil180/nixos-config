{ config, lib, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    lutris
  ];

  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };
}

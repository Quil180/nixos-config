{ config, lib, pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    lutris
    steam
  ];

  programs = {
    steam.enable = true;
  };
}

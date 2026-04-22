{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.flatpak = 
{
  pkgs,
  inputs,
  ...
}: {
  imports = [ ];

  # enabling core things, if not enabled
  xdg.enable = true;

  services.flatpak = {
    update = {
      onActivation = true;
      auto = {
        enable = true;
        onCalendar = "daily";
      };
    };
    packages = [
      "org.freedesktop.portal.Settings"
      "io.github.flattool.Warehouse"
      "org.vinegarhq.Sober"
    ];
  };

  home.sessionVariablesExtra = ''
    export XDG_DATA_DIRS="''${HOME}/.local/share/flatpak/exports/share:''${XDG_DATA_DIRS}"
  '';

  home.packages = with pkgs; [
    flatpak
  ];
}
;
}

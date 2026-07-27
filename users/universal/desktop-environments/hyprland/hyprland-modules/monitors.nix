{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.monitors = { ... }: {
    wayland.windowManager.hyprland.settings.monitor = [
      {
        output = "eDP-2";
        mode = "2560x1600@120";
        position = "0x0";
        scale = "1.25";
        bitdepth = 10;
      }
      {
        output = "eDP-1";
        mode = "2560x1600@120";
        position = "0x0";
        scale = "1.25";
        bitdepth = 10;
      }
      {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "1";
      }
    ];
  };
}

{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.monitors = { tags, ... }: {
    wayland.windowManager.hyprland.settings.monitor =
      # Built-in panels: laptops only.
      lib.optionals (builtins.elem "laptop" tags) [
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
      ]
      # Everything else (a desktop's real monitor) is configured by this
      # catch-all. Give a host its own entry here if it needs a fixed mode.
      ++ [
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = "1";
        }
      ];
  };
}

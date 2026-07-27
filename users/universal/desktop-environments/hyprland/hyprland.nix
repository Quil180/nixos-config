{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.hyprland =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      # importing configs for quickshell, foot, and wlogout, and rofi
      imports = [
        topConfig.flake.homeModules.quickshell
        topConfig.flake.homeModules.dunst
        topConfig.flake.homeModules.rofi
        topConfig.flake.homeModules.binds
        topConfig.flake.homeModules.misc
        topConfig.flake.homeModules.monitors
        topConfig.flake.homeModules.startup
        topConfig.flake.homeModules.power-management
      ];

      home.packages = with pkgs; [
        # bare essentials
        adwaita-icon-theme
        inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default # hyprcursor
        rose-pine-cursor
        grimblast # for screenshotting
        nwg-look # gtk settings editor
        qt5.qtwayland # graphics backend
        qt6.qtwayland # graphics backend
        wayland-logout # for easy logout
        wlogout # to easily logout
        wlr-randr # to change display primacy
        xdg-utils # xwayland support
        hyprpolkitagent # polkit
      ];

      # enabling hyprland and xwayland
      wayland.windowManager.hyprland = {
        enable = true;
        configType = "lua";
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland.enable = true;
        systemd = {
          enable = true;
          variables = [ "--all" ];
        };
        settings = {
          # Remove gaps when there's only one tiled window on a workspace
          workspace_rule = [
            {
              workspace = "w[t1]";
              gaps_in = 0;
              gaps_out = 0;
              no_border = true;
            }
          ];
          config = {
            # Gap settings
            general = {
              gaps_in = 5; # gaps between windows
              gaps_out = 5; # gaps from windows to screen edge
            };
            cursor = {
              no_hardware_cursors = true;
            };
            xwayland = {
              force_zero_scaling = true;
            };
            render = {
              direct_scanout = 2;
            };
          };
          env = [
            {
              _args = [
                "HYPRCURSOR_THEME"
                "rose-pine-hyprcursor"
              ];
            }
            {
              _args = [
                "HYPRCURSOR_SIZE"
                "24"
              ];
            }
            {
              _args = [
                "XCURSOR_THEME"
                "rose-pine-hyprcursor"
              ];
            }
            {
              _args = [
                "XCURSOR_SIZE"
                "24"
              ];
            }

            {
              _args = [
                "WLR_NO_HARDWARE_CURSORS"
                "1"
              ];
            }
            {
              _args = [
                "AQ_NO_HARDWARE_CURSORS"
                "1"
              ];
            }

            {
              _args = [
                "GDK_SCALE"
                "2"
              ];
            }
            {
              _args = [
                "ELECTRON_OZONE_PLATFORM_HINT"
                "wayland"
              ];
            }

            {
              _args = [
                "AQ_DRM_DEVICES"
                "/dev/dri/card1:/dev/dri/card2"
              ];
            }

            {
              _args = [
                "MOZ_ENABLE_WAYLAND"
                "1"
              ];
            }
          ];
          window_rule = [
            # XWayland Video Bridge
            {
              match = {
                class = "xwaylandvideobridge";
              };
              opacity = "0.0 override";
              no_anim = true;
              no_initial_focus = true;
              max_size = [
                1
                1
              ];
              no_blur = true;
              no_focus = true;
            }

            # Terminal & Browser Opacity
            {
              match = {
                class = "foot";
              };
              opacity = "0.9 override 0.85 override";
            }
            {
              match = {
                class = "firefox";
              };
              opacity = "1.0 override 0.95 override";
            }
          ];
        };
        plugins = [
          # to add more plugins just use the following
          # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.blahblah
        ];
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config = {
          common = {
            default = [ "gtk" ];
            "org.freedesktop.portal.OpenURI" = [ "gtk" ];
          };
          hyprland = {
            default = [
              "hyprland"
            ];
            "org.freedesktop.portal.OpenURI" = [ "hyprland" ];
          };
        };
      };
    };
}

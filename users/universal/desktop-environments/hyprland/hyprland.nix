{
  pkgs,
  inputs,
  ...
}: {
  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    # app configs below
    # ../bars/waybar/waybar.nix
    ../bars/quickshell/quickshell.nix
    dependent-apps/dunst.nix
    dependent-apps/rofi.nix

    # Hyprland modules below
    hyprland-modules/binds.nix
    hyprland-modules/misc.nix
    hyprland-modules/monitors.nix
    hyprland-modules/startup.nix
  ];

  home.packages = with pkgs; [
    # bare essentials
    adwaita-icon-theme
    inputs.rose-pine-hyprcursor.packages.${pkgs.stdenv.hostPlatform.system}.default # hyprcursor
    rose-pine-cursor
    grimblast # for screenshotting
    nwg-look # gtk settings editor
    swww # backgrounds/wallpapers
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    # rofi # app selector
    wayland-logout # for easy logout
    wlogout # to easily logout
    wlr-randr # to change display primacy
    xdg-utils # xwayland support
  ];

  # enabling hyprland and xwayland
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
    systemd.enable = false;
    systemd.variables = ["--all"];
    settings = {
      env = [
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        "HYPRCURSOR_SIZE,24"
        "XCURSOR_THEME,rose-pine-hyprcursor"
        "XCURSOR_SIZE,24"

        "GDK_SCALE,2"
        "ELECTRON_OZONE_PLATFORM_HINT, wayland"
      ];
      windowrule = [
        # XWayland Video Bridge
        "opacity 0.0 override, match:class xwaylandvideobridge"
        "no_anim on, match:class xwaylandvideobridge"
        "no_initial_focus on, match:class xwaylandvideobridge"
        "max_size 1 1, match:class xwaylandvideobridge"
        "no_blur on, match:class xwaylandvideobridge"
        "no_focus on, match:class xwaylandvideobridge"

        # Terminal & Browser Opacity
        "opacity 0.9 override 0.85 override, match:class foot"
        "opacity 1.0 override 0.95 override, match:class firefox"
      ];
    };
    extraConfig = ''
      xwayland {
        force_zero_scaling = true
      }
    '';
    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.stdenv.hostPlatform.system}.split-monitor-workspaces
      # to add more plugins just use the following
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.blahblah
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      pkgs.xdg-desktop-portal-gtk
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
    ];
    config = {
      common = {
        default = [ "gtk" ];
        "org.freedesktop.portal.OpenURI" = [ "gtk" ];
      };
      hyprland = {
        default = [ "gtk" "hyprland" ];
        "org.freedesktop.portal.OpenURI" = [ "gtk" ];
      };
    };
  };

  # making it so ozone apps use wayland
  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };
}

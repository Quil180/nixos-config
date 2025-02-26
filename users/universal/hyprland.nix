{
  pkgs,
  inputs,
  ...
}: let
  wallpaper = ../../wallpapers/wallpaper.jpg;
in {
  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    # app configs below
    hyprland/dependent-apps/waybar.nix
    hyprland/dependent-apps/dunst.nix
    hyprland/dependent-apps/foot.nix
    hyprland/dependent-apps/rofi.nix

    # Hyprland modules below
    hyprland/hyprland-modules/binds.nix
    hyprland/hyprland-modules/misc.nix
    hyprland/hyprland-modules/monitors.nix
    hyprland/hyprland-modules/startup.nix
  ];

  home.packages = with pkgs; [
    # bare essentials
    inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default # hyprcursor
    rose-pine-cursor
    grimblast # for screenshotting
    swww # backgrounds/wallpapers
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    rofi-wayland # app selector
    wayland-logout # for easy logout
    wlogout # to easily logout
    xdg-utils # xwayland support
    kdePackages.xwaylandvideobridge

    nwg-look
  ];

  # enabling hyprland and xwayland
  wayland.windowManager.hyprland = {
    enable = true;
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
      windowrulev2 = [
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "opacity 1.0 override 0.95 override,class:^(foot)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"
      ];
    };
    extraConfig = ''
      xwayland {
        force_zero_scaling = true
      }
    '';
    plugins = [
      pkgs.hyprlandPlugins.hyprsplit
    ];
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "BreezeX-RosePine-Linux";
    package = pkgs.rose-pine-cursor;
    size = 24;
  };

  # making it so ozone apps use wayland
  home.sessionVariables = {
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    MOZ_ENABLE_WAYLAND = "1";
  };
}

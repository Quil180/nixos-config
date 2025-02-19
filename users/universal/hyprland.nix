{
  pkgs,
  inputs,
  ...
}: let
  nix-colors-lib = inputs.nix-colors.lib.contrib {inherit pkgs;};
  wallpaper = ../../wallpapers/wallpaper.jpg;
in {
  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    inputs.nix-colors.homeManagerModules.default # importing nix-colors for ricing

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
    xdg-desktop-portal-hyprland # xwayland support
    xdg-utils # xwayland support

    nwg-look
    bibata-cursors
  ];

  colorScheme = nix-colors-lib.colorSchemeFromPicture {
    path = wallpaper;
    variant = "dark";
  };

  # enabling hyprland and xwayland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
    systemd.enable = false;
    systemd.variables = ["--all"];
    settings = {
      env = [
        "HYPRCURSOR_THEME,rose-pine-hyprcursor"
        "HYPRCURSOR_SIZE,24"
        "XCURSOR_THEME,rose-pine-hyprcursor"
        "XCURSOR_SIZE,24"

        "GDK_SCALE,2"
      ];
    };
    extraConfig = ''
      xwayland {
        force_zero_scaling = true
      }
    '';
  };

  # enabling xdg
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      common = {
        default = ["gtk"];
      };
      hyprland = {
        default = ["gtk" "hyprland"];
      };
      misc = {
        disable_hyprland_qtutils_check = "true";
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-hyprland
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

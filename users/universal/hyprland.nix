{ pkgs, inputs, ... }:
let
  nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
  wallpaper = ../../wallpapers/wallpaper.png;
in {

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    inputs.nix-colors.homeManagerModules.default # importing nix-colors for ricing

    # app configs below
    hyprland/dependent-apps/waybar.nix
    hyprland/dependent-apps/dunst.nix
    hyprland/dependent-apps/foot.nix

    # Hyprland modules below
    hyprland/hyprland-modules/binds.nix
    hyprland/hyprland-modules/misc.nix
    hyprland/hyprland-modules/monitors.nix
    hyprland/hyprland-modules/startup.nix
  ];
  
  home.packages = (with pkgs; [
    # bare essentials
    grimblast # for screenshotting
    hyprland-protocols # hyprland protocols
    swww # backgrounds/wallpapers
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    rofi-wayland # app selector
    wlogout # to easily logout
    xdg-desktop-portal-hyprland # xwayland support
    xdg-utils # xwayland support
  ]);

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
    systemd.variables = [ "--all" ];

  };

  # enabling xdg
  xdg.portal = {
    enable = true;
    config = {
      common = {
        default = [ "hyprland" ];
      };
      hyprland = {
        default = [ "hyprland" ];
      };
      misc = {
        disable_hyprland_qtutils_check = "true";
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # making it so ozone apps use wayland
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_SESSION_TYPE = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };
}

{ pkgs, ... }:

{

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    # app configs below
    hyprland/dependent-apps/waybar/waybar.nix
    hyprland/dependent-apps/dunst.nix

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
    swww # backgrounds
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    rofi-wayland # app selector
    wlogout # to easily logout
    xdg-desktop-portal-hyprland # xwayland support
    xdg-utils # xwayland support

  ]);
  
  # enabling hyprland and xwayland
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
    # systemd.enable = true;
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
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  # making it so ozone apps use wayland
  home.sessionVariables.NIXOS_OZONE_WL = "1";
}
{ pkgs, ... }:

{

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    # app configs below
    dependent-apps/waybar/waybar.nix
    dependent-apps/dunst.nix

    # Hyprland modules below
    hyprland-modules/binds.nix
    hyprland-modules/misc.nix
    hyprland-modules/monitors.nix
    hyprland-modules/startup.nix
  ];

  home.packages = (with pkgs; [
    # bare essentials
    dunst # notification daemon
    foot # terminal of choice
    grimblast # for screenshotting
    hyprland-protocols
    iosevka # font of choice
    networkmanagerapplet # network manager tray
    pavucontrol # volume control
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    rofi # app selector
    wl-clipboard # for clipboard support
    wlogout # to easily logout
    xdg-desktop-portal-hyprland # xwayland support
    xdg-utils # xwayland support

  ]);

  wayland.windowManager.hyprland = {
    enable = true;
    settings = { };
    xwayland = {
      enable = true;
    };
    # systemd.enable = true;
    systemd.variables = [ "--all" ];
  };

  home.sessionVariables.NIXOS_OZONE_WL = "1";
}

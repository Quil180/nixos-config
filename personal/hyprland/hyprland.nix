{ pkgs, ... }:

{

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    modules/waybar.nix
    modules/binds.nix
    modules/misc.nix
    modules/monitors.nix
  ];

  home.packages = (with pkgs; [
    # bare essentials
    foot # terminal of choice
    grim # for screenshotting
    hyprland-protocols
    iosevka # font of choice
    networkmanagerapplet # network manager tray
    pavucontrol # volume control
    qt5.qtwayland # graphics backend
    qt6.qtwayland # graphics backend
    rofi # app selector
    slurp # for screenshotting
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
}

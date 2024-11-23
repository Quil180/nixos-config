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
    hyprland-protocols
    wl-clipboard
    foot
    grim
    slurp
    xdg-utils
    xdg-desktop-portal-hyprland
    pavucontrol
    rofi
    wlogout
    qt6.qtwayland
    qt5.qtwayland
    iosevka

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

{ pkgs, ... }:

{

  home.packages = (with pkgs; [
    #hyprland-protocols
    wl-clipboard
    waybar
    sddm
    foot
    grim
    slurp
    xdg-utils
    #xdg-desktop-portal-hyprland
    pavucontrol
    rofi
    wlogout
    qt6.qtwayland
    qt5.qtwayland
  ]);

  programs.hyprland = {
    enable = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {};
    xwayland = {
      enable = true;
    };
    systemd.enable = true;
  };

}

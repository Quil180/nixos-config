{pkgs, ...}: let
  dwm-logout = pkgs.writeShellScriptBin "dwm-logout" ''
    choices="Shutdown\nReboot\nLogout\nSuspend"
    chosen=$(echo -e "$choices" | ${pkgs.rofi}/bin/rofi -dmenu -p "Logout")
    case "$chosen" in
        Shutdown) systemctl poweroff ;;
        Reboot) systemctl reboot ;;
        Logout) ${pkgs.procps}/bin/pkill dwm ;;
        Suspend) systemctl suspend ;;
    esac
  '';
in {
  services.xserver = {
    enable = true;
    windowManager.dwm = {
      enable = true;
    };
    displayManager.sessionCommands = ''
      ${pkgs.feh}/bin/feh --bg-scale /home/quil/Documents/GitRepos/nixos-config/wallpaper.png &
      ${pkgs.networkmanagerapplet}/bin/nm-applet &
      ${pkgs.dunst}/bin/dunst &
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
      ${pkgs.slstatus}/bin/slstatus &
    '';
  };

  environment.systemPackages = with pkgs; [
    dmenu
    st
    feh
    rofi
    dunst
    networkmanagerapplet
    brightnessctl
    pavucontrol
    polkit_gnome
    dwm-logout
    flameshot
    slstatus
  ];

  nixpkgs.overlays = [
    (final: prev: {
      dwm = prev.dwm.override {
        conf = ./config.h;
      };
      slstatus = prev.slstatus.override {
        conf = ./slstatus/config.h;
      };
    })
  ];
}

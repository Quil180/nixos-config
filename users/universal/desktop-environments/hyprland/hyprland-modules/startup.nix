{...}: let
  dotfiles = "~/.dotfiles";
in {
  wayland.windowManager.hyprland.settings.exec-once = [
    "bash -c 'sleep 1 && swww-daemon'"
    "bash -c 'sleep 1 && swwww img ${dotfiles}/wallpapers/wallpaper.jpg'"
    "bash -c 'sleep 1 && nm-applet --indicator'"
    "bash -c 'sleep 1 && asusctl -c 80'"
    "bash -c 'sleep 1 && asusctl led-mode static -c ffffff'"
    "bash -c 'sleep 1 && wl-paste --watch cliphist store'"
    "bash -c 'sleep 1 && dunst'"
    "bash -c 'sleep 1 && xwaylandvideobridge'" # for xwayland screensharing
    "bash -c 'sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP --all'"
    "bash -c 'sleep 1 && /usr/lib/polkit-kde-authentication-agent-1'"
    "bash -c 'sleep 1 && hyprctl setcursor rose-pine-hyprcursor 24'"
    "bash -c 'sleep 1 && rog-control-center'"
    "bash -c 'sleep 1 && qs -p ~/.config/quickshell/bar.qml'"
  ];
}

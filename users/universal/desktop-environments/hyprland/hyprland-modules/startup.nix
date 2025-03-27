{...}: let
  dotfiles = "~/.dotfiles";
in {
  wayland.windowManager.hyprland.settings.exec-once = [
    "swww-daemon"
    "swwww img ${dotfiles}/wallpapers/wallpaper.jpg"
    "nm-applet --indicator"
    "asusctl -c 100"
    "asusctl led-mode static -c ffffff"
    "wl-paste --watch cliphist store"
    "dunst"
    "xwaylandvideobridge" # for xwayland screensharing
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "/usr/lib/polkit-kde-authentication-agent-1"
    "hyprctl setcursor rose-pine-hyprcursor 24"
    "rog-control-center"
  ];
}

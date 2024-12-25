{pkgs, ...}:
let
  dotfiles = "~/.dotfiles";
in {
  wayland.windowManager.hyprland.settings.exec-once = [
    "swww-daemon"
    "swwww-daemon img ~/${dotfiles}/wallpapers/wallpaper.png"
    "nm-applet --indicator"
    "asusctl -c 80"
    "asusctl led-mode static -c ffffff"
    "waybar"
    "wl-paste --watch cliphist store"
    "dunst"
    "xwaylandvideobridge" # for xwayland screensharing
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
    "/usr/lib/polkit-kde-authentication-agent-1"
    "hyprctl setcursor rose-pine-hyprcursor 24"
  ];
}

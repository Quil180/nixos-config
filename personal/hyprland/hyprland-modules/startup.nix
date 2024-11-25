{pkgs, ...}:

{
	wayland.windowManager.hyprland.settings.exec-once = [
    "swww-daemon"
    "nm-applet --indicator"
    "asusctl -c 80"
    "wl-paste --watch cliphist store"
    "dunst"
    "xwaylandvideobridge" # for xwayland screensharing
	];
}

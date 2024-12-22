{pkgs, ...}:

{
	wayland.windowManager.hyprland.settings.exec-once = [
    "swww-daemon"
    "nm-applet --indicator"
    "asusctl -c 80"
    "rog-control-center"
    "wl-paste --watch cliphist store"
    "dunst"
    "xwaylandvideobridge" # for xwayland screensharing
	];
}

{pkgs, ...}:

{
	wayland.windowManager.hyprland.settings.exec-once = [
		"swww init" # for backgrounds
		"nm-applet" # network manager tray
		"xwaylandvideobridge" # for xwayland screensharing
		"wl-paste --watch cliphist store" # clipboard
		"asusctl -c 80"
	];
}

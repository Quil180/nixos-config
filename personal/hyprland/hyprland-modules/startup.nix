{pkgs, ...}:

{
	wayland.windowManager.hyprland.settings.exec-once = [
		"./personal/hyprland/hyprland-modules/scripts/startup.sh"
		"xwaylandvideobridge" # for xwayland screensharing
	];
}

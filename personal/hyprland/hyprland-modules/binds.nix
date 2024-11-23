{pkgs, ...}:

{
	wayland.windowManager.hyprland.settings = {
		"$mod" = "SUPER";
		"$term" = "foot";
		"$browser" = "firefox";
		"$file" = "ranger";
	};
	wayland.windowManager.hyprland.settings = {
		bindm = [
			# Move/resize windows with mainMod + LMB/RMB and dragging
			"$mod, mouse:272, movewindow"
			"$mod, mouse:273, resizeactive"
		];
		bind = [
			# basic keybinds
			"$mod, RETURN, exec, foot"
			"$mod, Q, killactive,"
			"$mod, F, togglefloating,"
			"$mod, R, exec, rofi -show drun"
			"$mod SHIFT, P, pseudo,"
			"$mod, J, togglesplit,"
			"$mod, L, exec, wlogout"
			"$mod SHIFT, F, fullscreen,0"

			# binds to launch apps
			"$mod, E, exec, $term -e $file"
			"$mod, W, exec, $browser"
			"$mod, D, exec, vesktop --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WebRTCPipeWireCapturer"
			"$mod, G, exec, steam"
			"$mod SHIFT, G, exec, lutris"
			"$mod, O, exec, obs QT_QPA_PLATFORM=wayland"
			"$mod, H, exec, foot -e btop"
			"$mod, I, exec, gimp"
			"$mod, M, exec, spotify-launcher"
			"$mod SHIFT, R, exec, rog-control-center" # for g14 control center
			"$mod ALT, R, exec, polychromatic-controller" # for razer center

			# keybinds to screenshot
			"$mod alt, P, exec, grimblast copy area && notify-send 'Zone Copied'"
			"$mod, P, exec, grimblast copy output && notify-send 'Current Screen Copied'"
			"$mod SHIFT, P, exec, grimblast screen output && notify-send 'All Screens Copied'"

			# volume control binds
			", xf86audioraisevolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
			", xf86audiolowervolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
			", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"

			# keybinds to move between workspaces
			"$mod, 1, workspace, 1"
			"$mod, 2, workspace, 2"
			"$mod, 3, workspace, 3"
			"$mod, 4, workspace, 4"
			"$mod, 5, workspace, 5"
			"$mod, 6, workspace, 6"
			"$mod, 7, workspace, 7"
			"$mod, 8, workspace, 8"
			"$mod, 9, workspace, 9"

			#moving windows while taking the user along
			"$mod SHIFT, 1, movetoworkspace, 1"
			"$mod SHIFT, 2, movetoworkspace, 2"
			"$mod SHIFT, 3, movetoworkspace, 3"
			"$mod SHIFT, 4, movetoworkspace, 4"
			"$mod SHIFT, 5, movetoworkspace, 5"
			"$mod SHIFT, 6, movetoworkspace, 6"
			"$mod SHIFT, 7, movetoworkspace, 7"
			"$mod SHIFT, 8, movetoworkspace, 8"
			"$mod SHIFT, 9, movetoworkspace, 9"

			# moving only windows between workspaces
			"$mod ALT, 1, movetoworkspacesilent, 1"
			"$mod ALT, 2, movetoworkspacesilent, 2"
			"$mod ALT, 3, movetoworkspacesilent, 3"
			"$mod ALT, 4, movetoworkspacesilent, 4"
			"$mod ALT, 5, movetoworkspacesilent, 5"
			"$mod ALT, 6, movetoworkspacesilent, 6"
			"$mod ALT, 7, movetoworkspacesilent, 7"
			"$mod ALT, 8, movetoworkspacesilent, 8"
			"$mod ALT, 9, movetoworkspacesilent, 9"

			# special workspace (scratchpad)
			"$mod, S, togglespecialworkspace, magic"
			"$mod SHIFT, S, movetoworkspace, special:magic"

			# Move focus with mainMod + arrow keys
			"$mod, left, movefocus, l"
			"$mod, right, movefocus, r"
			"$mod, up, movefocus, u"
			"$mod, down, movefocus, d"

			# Moving windows
			"$mod SHIFT, left, swapwindow, l"
			"$mod SHIFT, right, swapwindow, r"
			"$mod SHIFT, up, swapwindow, u"
			"$mod SHIFT, down, swapwindow, d"

			# resizing windows             x    y
			"$mod CTRL, left, resizewindowpixel, -60    0"
			"$mod CTRL, right, resizewindowpixel,  60    0"
			"$mod CTRL, down, resizewindowpixel,   0  -60"
			"$mod CTRL, up, resizewindowpixel,   0   60"
		];
	};
}
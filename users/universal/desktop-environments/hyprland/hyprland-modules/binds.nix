{...}: {
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
      "$mod SHIFT, L, exit,"
      "$mod SHIFT, F, fullscreen,0"

      # binds to launch apps
      "$mod, E, exec, $term -e $file"
      "$mod, W, exec, $browser --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland"
      # "$mod, D, exec, discord"
      "$mod, D, exec, discord --enable-features=WaylandWindowDecorations --ozone-platform-hint=auto --no-sandbox --disable-gpu --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WebRTCPipeWireCapturer"
      "$mod, G, exec, steam --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland"
      "$mod SHIFT, G, exec, lutris"
      "$mod, O, exec, obs QT_QPA_PLATFORM=wayland"
      "$mod, H, exec, foot -e btop"
      "$mod, I, exec, gimp"
      "$mod, M, exec, foot spotify_player"
      "$mod SHIFT, R, exec, rog-control-center" # for g14 control center
      "$mod ALT, R, exec, polychromatic-controller" # for razer center
      "$mod, V, exec, $term --hold vivado && notify-send 'Vivado was Started'"

      # keybinds to screenshot
      "$mod alt, P, exec, grimblast copy area && notify-send 'Zone Copied'"
      "$mod, P, exec, grimblast copy output && notify-send 'Current Screen Copied'"
      "$mod SHIFT, P, exec, grimblast screen output && notify-send 'All Screens Copied'"

      # volume control binds
      ", xf86audioraisevolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
      ", xf86audiolowervolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
      ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"

      # brightness control binds
      ", XF86MonBrightnessUp, exec, brightnessctl set +20%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 20%-"

      # keybinds to move between workspaces
      "$mod, 1, split-workspace, 1"
      "$mod, 2, split-workspace, 2"
      "$mod, 3, split-workspace, 3"
      "$mod, 4, split-workspace, 4"
      "$mod, 5, split-workspace, 5"
      "$mod, 6, split-workspace, 6"
      "$mod, 7, split-workspace, 7"
      "$mod, 8, split-workspace, 8"
      "$mod, 9, split-workspace, 9"
      "$mod, K, split-workspace, 20"
      #moving windows while taking the user along
      "$mod SHIFT, 1, split-movetoworkspace, 1"
      "$mod SHIFT, 2, split-movetoworkspace, 2"
      "$mod SHIFT, 3, split-movetoworkspace, 3"
      "$mod SHIFT, 4, split-movetoworkspace, 4"
      "$mod SHIFT, 5, split-movetoworkspace, 5"
      "$mod SHIFT, 6, split-movetoworkspace, 6"
      "$mod SHIFT, 7, split-movetoworkspace, 7"
      "$mod SHIFT, 8, split-movetoworkspace, 8"
      "$mod SHIFT, 9, split-movetoworkspace, 9"

      # moving only windows between workspaces
      "$mod ALT, 1, split-movetoworkspacesilent, 1"
      "$mod ALT, 2, split-movetoworkspacesilent, 2"
      "$mod ALT, 3, split-movetoworkspacesilent, 3"
      "$mod ALT, 4, split-movetoworkspacesilent, 4"
      "$mod ALT, 5, split-movetoworkspacesilent, 5"
      "$mod ALT, 6, split-movetoworkspacesilent, 6"
      "$mod ALT, 7, split-movetoworkspacesilent, 7"
      "$mod ALT, 8, split-movetoworkspacesilent, 8"
      "$mod ALT, 9, split-movetoworkspacesilent, 9"

      # special workspace (scratchpad)
      "$mod, S, togglespecialworkspace, magic"
      "$mod SHIFT, S, split-movetoworkspace, special:magic"

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

      # resizing windows                 x    y
      "$mod CTRL, left, resizeactive,  -60    0"
      "$mod CTRL, right, resizeactive,  60    0"
      "$mod CTRL, down, resizeactive,    0   60"
      "$mod CTRL, up, resizeactive,      0  -60"
    ];
  };
}

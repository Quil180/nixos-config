{ pkgs, ... }:

{

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    ./waybar.nix
  ];

  home.packages = (with pkgs; [
    # bare essentials
    hyprland-protocols
    wl-clipboard
    foot
    grim
    slurp
    xdg-utils
    #xdg-desktop-portal-hyprland
    pavucontrol
    rofi
    wlogout
    qt6.qtwayland
    qt5.qtwayland
    iosevka

  ]);

  wayland.windowManager.hyprland = {
    enable = true;
    settings = { };
    xwayland = {
      enable = true;
    };
    settings = {
      # setting the mod key
      "$mod" = "SUPER";
      # common aliases
      "$term" = "foot";
      "$browser" = "firefox";
      "$file" = "ranger";

      #actual keybindings
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
        "$mod SHIFT, R, exec, polychromatic-controller"

        # keybinds to screenshot
        " , Print, exec, grim - | wl-copy && wl-paste >  ~/Pictures/Screenshots/$(date + %Y-%m-%d_%H-%m-%s).png && notify-send 'Whole Screen Screenshotted, Saved, and Copied' -i ~/Pictures/Screenshots/$(date + %Y-%m-%d_%H-%m-%s).png"
        "$mod, Print, exec, grim -g '$(slurp -d)' - | wl-copy && wl-paste > ~/Pictures/Screenshots/$(date + %Y-%m-%d_%H-%m-%s).png && notify-send 'Zone Screenshotted, Saved, and Copied' -i ~/Pictures/Screenshots/$(date + %Y-%m-%d_%H-%m-%s).png"
        "alt, Print, exec, grim - | wl-copy && notify-send 'Whole Screen Copied'"
        "$mod alt, Print, exec, grim -g '$(slurp -d)' - | wl-copy && notify-send 'Zone Copied'"
        "$mod alt, P, exec, grim -g '$(slurp -d)' - | wl-copy && notify-send 'Zone Copied'"
        "$mod, P, exec, grim - | wl-copy && notify-send 'Whole Screen Copied'"

        # volume control binds
        ", xf86audioraisevolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", xf86audiolowervolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"

        # keybinds to move between workspaces
        "$mod, 1, exec, hyprsome workspace 1"
        "$mod, 2, exec, hyprsome workspace 2"
        "$mod, 3, exec, hyprsome workspace 3"
        "$mod, 4, exec, hyprsome workspace 4"
        "$mod, 5, exec, hyprsome workspace 5"
        "$mod, 6, exec, hyprsome workspace 6"
        "$mod, 7, exec, hyprsome workspace 7"
        "$mod, 8, exec, hyprsome workspace 8"
        "$mod, 9, exec, hyprsome workspace 9"

        #moving windows while taking the user along
        "$mod SHIFT, 1, exec, hyprsome move 1 && hyprsome workspace 1"
        "$mod SHIFT, 2, exec, hyprsome move 2 && hyprsome workspace 2"
        "$mod SHIFT, 3, exec, hyprsome move 3 && hyprsome workspace 3"
        "$mod SHIFT, 4, exec, hyprsome move 4 && hyprsome workspace 4"
        "$mod SHIFT, 5, exec, hyprsome move 5 && hyprsome workspace 5"
        "$mod SHIFT, 6, exec, hyprsome move 6 && hyprsome workspace 6"
        "$mod SHIFT, 7, exec, hyprsome move 7 && hyprsome workspace 7"
        "$mod SHIFT, 8, exec, hyprsome move 8 && hyprsome workspace 8"
        "$mod SHIFT, 9, exec, hyprsome move 9 && hyprsome workspace 9"

        # moving only windows between workspaces
        "$mod ALT, 1, exec, hyprsome move 1"
        "$mod ALT, 2, exec, hyprsome move 2"
        "$mod ALT, 3, exec, hyprsome move 3"
        "$mod ALT, 4, exec, hyprsome move 4"
        "$mod ALT, 5, exec, hyprsome move 5"
        "$mod ALT, 6, exec, hyprsome move 6"
        "$mod ALT, 7, exec, hyprsome move 7"
        "$mod ALT, 8, exec, hyprsome move 8"
        "$mod ALT, 9, exec, hyprsome move 9"

        # Example special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"

        # Move focus with mainMod + arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Moving windows
        "$mod S, left, swapwindow, l"
        "$mod S, right, swapwindow, r"
        "$mod S, up, swapwindow, u"
        "$mod S, down, swapwindow, d"

        # resizing windows             x    y
        "$mod CTRL, l, resizeactive, -60    0"
        "$mod CTRL, h, resizeactive,  60    0"
        "$mod CTRL, k, resizeactive,   0  -60"
        "$mod CTRL, j, resizeactive,   0   60"
      ];
    };
    extraConfig = ''
      workspace=1,monitor:eDP-2
      workspace=2,monitor:eDP-2
      workspace=3,monitor:eDP-2
      workspace=4,monitor:eDP-2
      workspace=5,monitor:eDP-2
      workspace=6,monitor:eDP-2
      workspace=7,monitor:eDP-2
      workspace=8,monitor:eDP-2
      workspace=9,monitor:eDP-2
      workspace=10,monitor:eDP-2

      workspace=11,monitor:HDMI-A-1
      workspace=12,monitor:HDMI-A-1
      workspace=13,monitor:HDMI-A-1
      workspace=14,monitor:HDMI-A-1
      workspace=15,monitor:HDMI-A-1
      workspace=16,monitor:HDMI-A-1
      workspace=17,monitor:HDMI-A-1
      workspace=18,monitor:HDMI-A-1
      workspace=19,monitor:HDMI-A-1
      workspace=110,monitor:HDMI-A-1
    '';
    # systemd.enable = true;
    systemd.variables = [ "--all" ];
  };


  # customizing foot with a different font
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "iosevka-bold:size=10";
        dpi-aware = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

}

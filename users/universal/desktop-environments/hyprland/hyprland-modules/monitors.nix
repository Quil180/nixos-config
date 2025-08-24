{...}: {
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        # "HDMI-A-1,1920x1080@120,0x-1080,1,"
        "DP-3,1920x1080@120,-1920x0,1"
        "eDP-2,2560x1600@120,0x0,1.25,"
        "eDP-1,2560x1600@120,0x0,1.25,"
        ", preferred, auto, 1"

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

      workspace=11,monitor:DP-3
      workspace=12,monitor:DP-3
      workspace=13,monitor:DP-3
      workspace=14,monitor:DP-3
      workspace=15,monitor:DP-3
      workspace=16,monitor:DP-3
      workspace=17,monitor:DP-3
      workspace=18,monitor:DP-3
      workspace=19,monitor:DP-3
      workspace=110,monitor:DP-3
    '';
  };
}

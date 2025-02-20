{...}: {
  wayland.windowManager.hyprland = {
    settings = {
      monitor = [
        "eDP-2,2560x1600@120,0x0,1.25,"
        "eDP-1,2560x1600@120,0x0,1.25,"
        "HDMI-A-1,1920x1080@120,0x-1080,1,"
        "DP-3,1920x1080@120,0x-1080,1"
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
  };
}

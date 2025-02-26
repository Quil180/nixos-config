{
  pkgs,
  config,
  ...
}: let
  base00 = "cc241d";
  base01 = "cc241d";
  base02 = "cc241d";
  base03 = "cc241d";
  base04 = "cc241d";
  base05 = "cc241d";
  base06 = "cc241d";
  base08 = "cc241d";
  base09 = "cc241d";
  base0A = "cc241d";
  base0B = "cc241d";
  base0C = "cc241d";
  base0D = "cc241d";
in {
  home.packages = with pkgs; [
    dunst
    libnotify
  ];

  services.dunst = {
    enable = true;
    settings = {
      global = {
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
        follow = "mouse";
        font = "iosevka 12";
        format = "<b>%s</b>\\n%b";
        frame_width = 2;
        geometry = "500x5-5+30";
        horizontal_padding = 8;
        icon_position = "off";
        line_height = 0;
        markup = "full";
        padding = 8;
        separator_height = 2;
        transparency = 10;
        word_wrap = true;

        # coloring
        frame_color = "#${base05}";
        separator_color = "#${base05}";
      };
      urgency_low = {
        background = "#${base01}";
        foreground = "#${base03}";
      };
      urgency_normal = {
        background = "#${base02}";
        foreground = "#${base05}";
      };
      urgency_critical = {
        background = "#${base08}";
        foreground = "#${base06}";
        timeout = 0;
      };

      shortcuts = {
        context = "mod4+grave";
        close = "mod4+shift+space";
      };
    };
  };
}

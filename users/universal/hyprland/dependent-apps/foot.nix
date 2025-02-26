{config, ...}: let
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
  base0E = "cc241d";
in {
  programs.foot.settings.colors = {
    alpha = "1.0";
    background = "000000";
    foreground = "ffffff";
    flash = "${base08}";
    flash-alpha = "0.5";

    regular0 = "${base00}"; # black
    regular1 = "${base08}"; # red
    regular2 = "${base0B}"; # green
    regular3 = "${base0A}"; # yellow
    regular4 = "${base0D}"; # blue
    regular5 = "${base0E}"; # magenta
    regular6 = "${base0C}"; # cyan
    regular7 = "${base06}"; # white

    bright0 = "${base00}"; # bright black
    bright1 = "${base08}"; # bright red
    bright2 = "${base0B}"; # bright green
    bright3 = "${base09}"; # bright yellow
    bright4 = "${base0D}"; # bright blue
    bright5 = "${base0E}"; # bright magenta
    bright6 = "${base0C}"; # bright cyan
    bright7 = "${base06}"; # bright white
  };
}

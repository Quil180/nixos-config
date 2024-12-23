{pkgs, config, ... }:
{
  programs.foot.settings.colors = with config.colorScheme.palette; {
    alpha = "1.0";
    background = "${base00}";
    foreground = "${base06}";
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

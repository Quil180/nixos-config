{
  config,
  lib,
  ...
}: {
  # customizing foot with a different font
  programs.foot = {
    enable = true;
    settings = {
      main.include = lib.mkForce [ ];
      colors = lib.mkForce { };
      colors-dark = with config.lib.stylix.colors; {
        background = base00;
        foreground = base05;
        regular0 = base00;
        regular1 = base08;
        regular2 = base0B;
        regular3 = base0A;
        regular4 = base0D;
        regular5 = base0E;
        regular6 = base0C;
        regular7 = base05;
        bright0 = base03;
        bright1 = base08;
        bright2 = base0B;
        bright3 = base0A;
        bright4 = base0D;
        bright5 = base0E;
        bright6 = base0C;
        bright7 = base07;
        "16" = base09;
        "17" = base0F;
        "18" = base01;
        "19" = base02;
        "20" = base04;
        "21" = base06;
        alpha = config.stylix.opacity.terminal;
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  services.network-manager-applet.enable = true;
}

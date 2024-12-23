{pkgs, ...}:

{
  # customizing foot with a different font
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "iosevka:size=16";
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

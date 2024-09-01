{pkgs, ...}:

{
  home.packages = (with pkgs; [
    waybar
  ]);

  programs.waybar = {
    enable = true;
  };
}

{pkgs, ...}: {
  home.packages = with pkgs; [
    ranger
  ];
  programs.ranger = {
    enable = true;
  };
}

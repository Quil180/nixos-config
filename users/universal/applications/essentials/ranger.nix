{pkgs, ...}: {
  home.packages = with pkgs; [
    ranger
    unzip
  ];
  programs.ranger = {
    enable = true;
  };
}

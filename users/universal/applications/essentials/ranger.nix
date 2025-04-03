{pkgs, ...}: {
  home.packages = with pkgs; [
    ranger
    unzip
    w3m
  ];
  programs.ranger = {
    enable = true;
    # extraConfig = "set preview_images true\nset preview_images_method foot";
  };
}

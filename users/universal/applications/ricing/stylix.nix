{pkgs, ...}: let
  wallpaper = ../../../../wallpapers/wallpaper.jpg;
in {
  stylix = {
    enable = true;
    polarity = "dark";

    image = wallpaper;

    cursor = {
      package = pkgs.rose-pine-cursor;
      name = "BreezeX-RosePine-Linux";
      size = 24;
    };
    fonts = {
      monospace = {
        package = pkgs.iosevka;
        name = "iosevka";
      };
      sansSerif = {
        package = pkgs.iosevka;
        name = "iosevka";
      };
      serif = {
        package = pkgs.iosevka;
        name = "iosevka";
      };
    };

    opacity = {
      desktop = 0.0;
      terminal = 1.0;
    };
  };
}

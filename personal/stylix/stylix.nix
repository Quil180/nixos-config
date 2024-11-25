{pkgs, ...}:
let
  wallpaper = ../../wallpapers/frieren_reading.jpg;
in {
  stylix = {
    enable = true;
    image = wallpaper;
    polarity = "dark";
  };
}

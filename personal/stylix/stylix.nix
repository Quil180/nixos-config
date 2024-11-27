{pkgs, inputs, ...}:
let
  wallpaper = ../../wallpapers/frieren_reading.jpg;
in {
  imports = [
    inputs.stylix.homeManagerModules.stylix
  ];
  stylix = {
    enable = true;
    image = wallpaper;
    polarity = "dark";
  };
}

{
  config,
  pkgs,
  ...
}: let
  python = let
    packageOverrides = self: super: {
      opencv4 = super.opencv4.overrideAttrs (old: rec {
        enableGtk2 = pkgs.gtk2; # pkgs.gtk2-x11 # pkgs.gnome2.gtk;
        # doCheck = false;
      });
    };
  in
    pkgs.python3.override {
      inherit packageOverrides;
      self = python;
    };
in {
  home.packages = with pkgs; [
  ];
}

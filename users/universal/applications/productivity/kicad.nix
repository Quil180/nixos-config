_: {
  flake.homeModules.kicad =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        kicad
      ];
    };
}

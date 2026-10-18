_: {
  flake.homeModules.kicad =
    { pkgs, ... }:
    {
      persist.directories = [ ".config/kicad" ];

      home.packages = with pkgs; [
        kicad
      ];
    };
}

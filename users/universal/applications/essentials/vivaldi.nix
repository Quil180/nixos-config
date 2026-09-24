_: {
  flake.homeModules.vivaldi =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        vivaldi
      ];
    };
}

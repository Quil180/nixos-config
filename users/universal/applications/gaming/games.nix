_: {
  flake.homeModules.games =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        prismlauncher
      ];
    };
}

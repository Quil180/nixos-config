_: {
  flake.homeModules.games =
    { pkgs, ... }:
    {
      # Steam itself is installed system-side (nixosModules.games), but its
      # library and login live here.
      persist.directories = [
        ".local/share/Steam"
        ".local/share/PrismLauncher"
      ];

      home.packages = with pkgs; [
        prismlauncher
      ];
    };
}

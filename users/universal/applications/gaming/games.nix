_: {
  flake.homeModules.games =
    { pkgs, ... }:
    {
      # Steam itself is installed system-side (nixosModules.games), but its
      # library and login live here; .steam holds Steam's links into it.
      # .factorio: Factorio's saves and settings.
      persist.directories = [
        ".local/share/Steam"
        ".steam"
        ".local/share/PrismLauncher"
        ".factorio"
        ".local/share/goverlay"
        ".config/goverlay"
        ".config/vkBasalt"
        ".config/vkSumi"
      ];

      home.packages = with pkgs; [
        prismlauncher
      ];
    };
}

_: {
  flake.homeModules.spotify-cli = { pkgs, ... }: {
    # spotify-player keeps its login (credentials.json) in its cache dir.
    persist.directories = [ ".cache/spotify-player" ];

    home.packages = with pkgs; [
      spotify-player
    ];

    programs.spotify-player.enable = true;
  };
}

{pkgs, ...}: {
  home.packages = with pkgs; [
    spotify-player
  ];

  programs.spotify-player.enable = true;
}

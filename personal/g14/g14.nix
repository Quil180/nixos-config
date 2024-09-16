{pkgs, ...}:
{
  home.packages = (with pkgs; [
    # programs used on my g14 laptop

    # essentials I use often
    vesktop
    spotify-player
    gimp
    polychromatic
  ]);

  # enabling the programs
  programs.spotify-player.enable = true;
}

{pkgs, ...}:
{
  home.packages = (with pkgs; [
    # programs used on my g14 laptop

    # essentials I use often
    vesktop
    spotify-player
    gimp
    polychromatic
    neofetch
  ]);

  # enabling the programs
  programs.spotify-player.enable = true;
}

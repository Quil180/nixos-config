{pkgs, ...}:
{
  home.packages= (with pkgs; [
    texlive.combined.scheme-full
  ]);

  programs.texlive = {
    enable = true;
  };
}

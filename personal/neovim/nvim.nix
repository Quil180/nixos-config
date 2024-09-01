{ pkgs, ... }:

{

  programs.neovim = {
    enable = true;
  };

  # importing my config for neovim
  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}

{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
    ];
  };

  # importing my config for neovim
  # home.file."./.config/nvim/" = {
  #   source = ./nvim;
  #   recursive = true;
  # };
  
}

{ config, pkgs, inputs, ... }:

{
  home.username = "quil";
  home.homeDirectory = "/home/quil";

  # importing my custom external modules
  imports = [
    personal/neovim/nixvim.nix
    personal/hyprland/hyprland.nix # hyprland config
    personal/ranger/ranger.nix # ranger config
    personal/bash/bash.nix # bash config
    personal/git/git.nix # git config
    personal/stylix/stylix.nix # stylix setup
    personal/firefox/firefox.nix # firefox config
  ];

  # my original nixos install version
  home.stateVersion = "24.05";

  # user packages that I'd like installed no matter my imports
  home.packages = [
    # bare essentials regardless of the imported modules
    pkgs.zoxide
  ];

  # setting the editor of choice to neovim
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

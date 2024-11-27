{ config, pkgs, inputs, ... }:

{
  home.username = "quil";
  home.homeDirectory = "/home/quil";

  # importing my custom external modules
  imports = [
    personal/neovim/neovim.nix # neovim config
    personal/hyprland/hyprland.nix # hyprland config
    personal/ranger/ranger.nix # ranger config
    personal/bash/bash.nix # bash config
    personal/git/git.nix # git config
    personal/stylix/stylix.nix # stylix setup
    personal/firefox/firefox.nix # firefox config
    personal/vesktop/vesktop # vesktop config
  ];

  # my original nixos install version
  home.stateVersion = "24.05";

  # user packages that I'd like installed no matter my imports
  home.packages = ( with pkgs; [
    # bare essentials regardless of the imported modules
    zoxide # for better cd
    networkmanagerapplet # network manager tray
    pavucontrol # volume control
    wl-clipboard # for clipboard support
    foot # terminal of choice
    brightnessctl # brightness/backlight control
  ]);

  # setting the editor of choice to neovim
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

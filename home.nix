{ config, pkgs, inputs, ... }:

{
  home.username = "quil";
  home.homeDirectory = "/home/quil";

  # importing my custom external modules
  imports = [

    personal/neovim/nvim.nix # neovim config
    personal/hyprland/hyprland.nix # hyprland config
    personal/ranger/ranger.nix # ranger config
    personal/bash/bash.nix # bash config
    personal/git/git.nix # git config
  ];

  # my original nixos install version
  home.stateVersion = "24.05";

  # user packages that I'd like installed no matter my imports
  home.packages = [
    # bare essentials regardless of the imported modules
    # pkgs.firefox
    pkgs.zsh
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/quil/etc/profile.d/hm-session-vars.sh
  #

  # setting the editor of choice to neovim
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # firefox config
  programs.firefox.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

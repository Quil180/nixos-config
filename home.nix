{ config, pkgs, ... }:

{
  home.username = "quil";
  home.homeDirectory = "/home/quil";

  # importing my custom external configs
  imports = [
    personal/neovim/nvim.nix # neovim config
    personal/hyprland/hyprland.nix # hyprland config
    #personal/ranger/ranger.nix # ranger config
  ];

  # my original nixos install version
  home.stateVersion = "24.05";

  # user packages that I'd like installed no matter my imports
  home.packages = [
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
    EDITOR = "neovim";
  };

  # bash config
  programs.bash = {
    enable = true;
    shellAliases = {
      # update aliases
      updh = "home-manager switch --flake ~/.dotfiles#quil";
      updf = "nix flake update";
      upds = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos-quil";
      updb = "source ~/.bashrc";
      upda = "updf && upds && updh && updb";
      # editing file aliases
      edith = "nvim ~/.dotfiles/home.nix";
      edits = "nvim ~/.dotfiles/configuration.nix";
      editf = "nvim ~/.dotfiles/flake.nix";
    };
  };

  # git config
  programs.git = {
    enable = true;
    userName = "Quil";
    userEmail = "quil180gaming@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

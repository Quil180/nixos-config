{pkgs, ...}:

{
  # shell config
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # update aliases
      updh = "home-manager switch --flake ~/.dotfiles#quil";
      updf = "nix flake update";
      upds = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos-quil";
      updb = "source ~/.zshrc";
      upda = "updf && upds && updh && updb";
      # editing file aliases
      edith = "nvim ~/.dotfiles/home.nix";
      edits = "nvim ~/.dotfiles/configuration.nix";
      editf = "nvim ~/.dotfiles/flake.nix";
      editv = "nvim ~/.dotfiles/personal/neovim/";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}

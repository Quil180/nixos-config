{ config, pkgs, inputs, ...}:

{
  imports = [
    personal/bash/bash.nix
    personal/firefox/firefox.nix
    personal/git/git.nix
    personal/hyprland/hyprland.nix
    personal/neovim/neovim.nix
    # personal/stylix/stylix.nix
    personal/vesktop/vesktop.nix
  ];

  home = {
    username = "quil";
    homeDirectory = "/home/quil";
    stateVersion = "24.05";
    sessionVariables.EDITOR = "nvim";
    packages = (with pkgs; [
      brightnessctl # brightness control
      foot # terminal emulator
      networkmanagerapplet # network manager tray
      pavucontrol # sound control GUI
      wl-clipboard # clipboard
      zoxide # better cd
    ]);
  };
  programs.home-manager.enable = true;
}

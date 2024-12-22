{ config, pkgs, inputs, ...}:

{
  imports = [
    ../universal/home-manager/bash.nix
    ../universal/home-manager/firefox.nix
    ../universal/home-manager/git.nix
    ../universal/home-manager/hyprland.nix
    # ../universal/home-manager/neovim.nix
    # ../universal/home-manager/stylix.nix
    ../universal/home-manager/vesktop.nix
    ../universal/home-manager/music.nix
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

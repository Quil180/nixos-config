{ config, pkgs, inputs, ...}:

{
  imports = [
    ../universal/bash.nix
    ../universal/firefox.nix
    ../universal/git.nix
    ../universal/hyprland.nix
    # ../universal/neovim.nix
    # ../universal/stylix.nix
    ../universal/vesktop.nix
    ../universal/music.nix
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

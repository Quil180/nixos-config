{ config, pkgs, inputs, ...}:

{
  imports = [
    users/universal/home-manager/bash.nix
    users/universal/home-manager/firefox.nix
    users/universal/home-manager/git.nix
    users/universal/home-manager/hyprland.nix
    users/universal/home-manager/neovim.nix
    # users/universal/home-manager/stylix.nix
    users/universal/home-manager/vesktop.nix
    users/universal/home-manager/music.nix
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

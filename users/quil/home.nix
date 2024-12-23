{ config, pkgs, inputs, ...}:

{
  imports = [
    ../universal/bash.nix
    ../universal/firefox.nix
    ../universal/git.nix
    ../universal/hyprland.nix
    # ../universal/neovim.nix
    ../universal/discord.nix
    ../universal/music.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
  };

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

      obs-studio
    ]);
  };
  programs.home-manager.enable = true;
}

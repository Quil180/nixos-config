{ config, pkgs, inputs, ...}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops

    ../universal/bash.nix
    ../universal/firefox.nix
    ../universal/git.nix
    ../universal/hyprland.nix
    ../universal/neovim.nix
    ../universal/discord.nix
    ../universal/music.nix
    ../universal/sops.nix
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
      mpv # terminal video player
      networkmanagerapplet # network manager tray
      pavucontrol # sound control GUI
      wl-clipboard # clipboard
      zoxide # better cd

      obs-studio

      age
    ]);
  };

  sops = {
    age.keyFile = "/home/quil/.config/sops/age/keys.txt";
  };

  programs.home-manager.enable = true;
}

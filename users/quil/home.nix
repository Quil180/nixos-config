{pkgs, ...}: {
  imports = [
    ../universal/bash.nix
    ../universal/discord.nix
    ../universal/firefox.nix
    ../universal/git.nix
    ../universal/hyprland.nix
    ../universal/latex.nix
    ../universal/music.nix
    ../universal/office.nix
    ../universal/password-manager.nix
    ../universal/revolt.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  home = {
    username = "quil";
    homeDirectory = "/home/quil";
    stateVersion = "24.05";
    sessionVariables.EDITOR = "nvim";
    packages = with pkgs; [
      age # secrets management
      brightnessctl # brightness control
      foot # terminal emulator
      mpv # terminal video player
      networkmanagerapplet # network manager tray
      pavucontrol # sound control GUI
      wl-clipboard # clipboard
      zoxide # better cd
    ];
  };

  programs.home-manager.enable = true;
}

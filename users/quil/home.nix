{pkgs, ...}: {
  imports = [
    # desktop environments below
    ../universal/desktop-environments/hyprland/hyprland.nix

    # essential applications below
    ../universal/applications/essentials/bash.nix
    ../universal/applications/essentials/firefox.nix
    ../universal/applications/essentials/music.nix
    ../universal/applications/essentials/password-manager.nix
    ../universal/applications/essentials/ranger.nix
    ../universal/applications/essentials/vivaldi.nix

    # gaming applications below
    ../universal/applications/gaming/games.nix
    # ../universal/applications/gaming/creamlinux.nix

    # productivity applications below
    ../universal/applications/productivity/filezilla.nix
    ../universal/applications/productivity/git.nix
    ../universal/applications/productivity/latex.nix
    ../universal/applications/productivity/office.nix

    # programming languages
    ../universal/applications/productivity/programming/verilog.nix
    ../universal/applications/productivity/programming/rust.nix
    # ../universal/applications/productivity/programming/python.nix
    # ../universal/applications/productivity/programming/vscode.nix

    # ricing applications below
    ../universal/applications/ricing/stylix.nix

    # social applications below
    ../universal/applications/social/discord.nix
    ../universal/applications/social/revolt.nix
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

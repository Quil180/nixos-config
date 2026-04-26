{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.home.quil.module =
    {
      pkgs,
      username,
      inputs,
      ...
    }:
    {
      imports = with topConfig.flake.homeModules; [
        persist
        hyprland
        bash
        chromium
        firefox
        music
        neovim
        password-manager
        ranger
        games
        git
        kicad
        latex
        office
        zoom
        cpp
        verilog
        rust
        python
        antigravity
        stylix
        discord
        flatpak
      ];

      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
        sessionVariables = {
          EDITOR = "nvim";
          BROWSER = "firefox";
        };
        packages = with pkgs; [
          age # secrets management
          brightnessctl # brightness control
          foot # terminal emulator
          mpv # terminal video player
          networkmanagerapplet # network manager tray
          pavucontrol # sound control GUI
          wl-clipboard # clipboard
          zoxide # better cd

          gemini-cli # temporarily putting here for the sake of not needing nix-shell command
        ];
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*" = {
          identityFile = "/run/agenix/snowflake";
        };
      };

      programs.home-manager.enable = true;
    };
}

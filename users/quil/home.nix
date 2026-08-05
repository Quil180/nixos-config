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
      config,
      ...
    }:
    {
      imports = with topConfig.flake.homeModules; [
        # persist
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
        cpp
        verilog
        # antigravity
        stylix
        discord
        # flatpak
      ];

      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
        permittedInsecurePackages = [
          "electron-39.8.10"
        ];
      };

      age = {
        identityPaths = [
          "/home/${username}/.ssh/id_ed25519"
        ];
        secrets = {
          git_identity = {
            file = ../../secrets/git_identity.age;
          };
          snowflake = {
            file = ../../secrets/snowflake.age;
            mode = "600";
          };
        };
      };

      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
        pointerCursor.enable = true;
        sessionVariables = {
          EDITOR = "nvim";
          BROWSER = "firefox";
        };
        packages = with pkgs; [
          inputs.agenix.packages.${stdenv.hostPlatform.system}.default # secrets management
          brightnessctl # brightness control
          foot # terminal emulator
          mpv # terminal video player
          networkmanagerapplet # network manager tray
          pavucontrol # sound control GUI
          wl-clipboard # clipboard
          zoxide # better cd

          pi-coding-agent # pi coding agent for coding or something
        ];
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings = {
          "*" = {
            identityFile = config.age.secrets.snowflake.path;
          };
        };
      };

      programs.home-manager.enable = true;
    };
}

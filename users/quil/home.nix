{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  # The shared home profile, imported by every per-host home target
  # (configurations.home."quil@<host>" — see users/quil/targets.nix).
  # Anything that must differ per host branches on the `tags` extraSpecialArg,
  # e.g. lib.mkIf (builtins.elem "laptop" tags) … — the traits themselves are
  # declared on the host's nixos entry, not here.
  flake.homeModules.quil =
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
        pi
        cpp
        verilog
        # antigravity
        stylix
        discord
        flatpak

        creamlinux
      ];

      nixpkgs.config = {
        allowUnfree = true;
      };

      age = {
        identityPaths = [
          "/home/${username}/.ssh/id_ed25519"
        ];
        secrets = {
          git_identity = {
            file = ../../secrets/git_identity.age;
            path = "${config.home.homeDirectory}/.local/state/git_identity";
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
          inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default # secrets management
          brightnessctl # brightness control
          foot # terminal emulator
          mpv # terminal video player
          networkmanagerapplet # network manager tray
          pavucontrol # sound control GUI
          wl-clipboard # clipboard
          zoxide # better cd
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

{
  topConfig,
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
        bash
        persist
        hyprland
        # chromium
        # creamlinux
        firefox
        spotify-cli
        neovim
        bitwarden
        ranger
        games
        git
        # kicad
        latex
        office
        # deepseek-harness
        # cpp
        # verilog
        antigravity
        stylix
        discord

        # Flatpak applications (modular: import only what you want)
        # vkSumi
        fluxer
        # warehouse
        # goverlay
        # sober
      ];

      nixpkgs.config = {
        allowUnfree = true;
      };

      persist.directories = [ ".local/share/zoxide" ];

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

      home.shellAliases =
        let
          dotfiles = "${config.home.homeDirectory}/.dotfiles";
          # True when this profile is built into a NixOS host (integratedHome)
          # rather than by standalone home-manager.
          integrated = config.submoduleSupport.enable;
        in
        {
          # replacing cd with zoxide
          cd = "z";

          # update aliases
          updh =
            if integrated then
              "echo 'updh: home-manager is part of the NixOS config on this host, run upds instead' >&2; false"
            else
              "home-manager switch --flake ${dotfiles} -b backup";
          updf = "cd ${dotfiles} && nix flake update --flake ${dotfiles}";
          upds = "sudo nixos-rebuild switch --flake ${dotfiles}";
          updb = "source ~/.config/zsh/.zshrc";
          upda = if integrated then "updf && upds && updb" else "updf && upds && updh && updb";

          # NixOS configuration manager
          polaris = "${dotfiles}/install.sh";

          # personal SSH
          vlsi = "export TERM=ansi; ssh -Y yo485591@vlsi.eecs.ucf.edu";
        };

      # The standalone CLI only; integrated hosts are switched by nixos-rebuild.
      programs.home-manager.enable = !config.submoduleSupport.enable;
    };
}

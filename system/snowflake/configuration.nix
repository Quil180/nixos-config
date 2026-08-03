{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.snowflake.module =
    {
      pkgs,
      inputs,
      username,
      system,
      config,
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [
        # --- Core System & Hardware ---
        snowflake_hardware
        disko
        # simple_disko
        # determinate
        secrets
        # persist
        security
        # proxmox_vm
        # server_base

        # --- Hardware Support ---
        amd
        g14

        # --- Desktop Environments & Window Managers ---
        hyprland
        # cinnamon
        # dwm

        # --- Display Managers ---
        sddm
        # ly

        # --- System Services ---
        sound
        bluetooth
        # qt5
        # monitoring

        # --- Virtualization & Containers ---
        virtualisation
        # docker
        # flatpak

        # --- VPNs & Networking ---
        hamachi
        # tailscale
        # zerotier

        # --- Applications & Gaming ---
        games
        winboat
        # kiwix
        # teamviewer
        # vncviewer

        # --- AI Services ---
        # hermes
        # ollama
        llamacpp
        # openwebui
      ];

      networking = {
        hostName = "snowflake";
        networkmanager = {
          enable = true;
          wifi.powersave = true;
          plugins = with pkgs; [
            networkmanager-openconnect
            networkmanager-openvpn
          ];
        };
        firewall = {
          enable = true;
          allowedTCPPorts = [
            # Place ports here
          ];
        };
      };
      # To ensure all firmware is loaded
      hardware.enableAllFirmware = true;
      hardware.enableRedistributableFirmware = true;

      time.timeZone = "America/New_York";

      # default packages regardless of user/host
      environment.systemPackages = with pkgs; [
        appimage-run
        btop-rocm
        fastfetch
        git
        gh
        neovim
        sops
        ranger
        wget
        zsh
        inputs.agenix.packages.${system}.default
      ];

      fonts.packages = with pkgs; [
        font-awesome
        font-awesome_5
        font-awesome_4
        powerline-fonts
        nerd-fonts.iosevka
        nerd-fonts.symbols-only
      ];

      age = {
        identityPaths = lib.mkForce [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key"
        ];
        secrets = {
          quil_password.file = ../../secrets/quil_password.age;
          git_identity = {
            file = ../../secrets/git_identity.age;
            owner = username;
          };
          snowflake = {
            file = ../../secrets/snowflake.age;
            owner = "${username}";
            mode = "600";
          };
        };
      };

      # default user settings regardless of host/user
      users = {
        defaultUserShell = pkgs.zsh;
        mutableUsers = true;
        users = {
          root.initialPassword = "1234";
          ${username} = {
            isNormalUser = true;
            password = "1234";
            # hashedPasswordFile = config.age.secrets.quil_password.path;
            extraGroups = [
              "networkmanager"
              "wheel"
              "storage"
              "video"
              "kvm"
              "docker"
            ];
            openssh.authorizedKeys.keys = [
              (builtins.readFile ../keys/id_snowflake.pub)
            ];
          };
        };
      };

      system = {
        stateVersion = "26.05"; # KEEP THIS THE SAME
        # auto updates
        autoUpgrade = {
          enable = false;
          flake = inputs.self.outPath;
          flags = [
            "--update-input"
            "nixpkgs"
            "-L"
          ];
          dates = "02:00";
          randomizedDelaySec = "45min";
        };
      };

      # enabling programs to be managed by nixos
      programs = {
        appimage = {
          enable = true;
          binfmt = true;
        };
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
        };
        neovim = {
          # Enabling customization of neovim and stable version
          enable = true;

          # setting neovim to be default editor and extra aliases
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
        };
        nix-ld.enable = true;
        zsh.enable = true;
      };

      # enabling the services I need system wide
      services = {
        # ssh support
        openssh.enable = true;

        # printing support via CUPS
        printing.enable = true;

        # automount drives
        devmon.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;

        # For gpg
        pcscd.enable = true;

        # For authentication
        gnome.gnome-keyring.enable = true;

        # For firmware updating
        fwupd.enable = true;
      };

      systemd.services.nvidia-powerd.enable = lib.mkForce false;
      systemd.user.services.blueman-applet.enable = lib.mkForce false;

      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
        permittedInsecurePackages = [
          "electron-40.10.5"
        ];
      };
      nix = {
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 1w";
        };
        optimise = {
          automatic = true;
          dates = "daily";
        };
        settings = {
          auto-optimise-store = true;
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };
      };
    };
}

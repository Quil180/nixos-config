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
          wireguard_client
        # --- Core System & Hardware ---
        snowflake_hardware
        disko
        # simple_disko
        # determinate
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

        # --- VPNs & Networking ---
        # hamachi
        # tailscale
        # zerotier

        # --- Applications & Gaming ---
        games
        # winboat
        # kiwix
        # teamviewer
        # vncviewer

        # --- AI Services ---
        hermes
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

      # time.timeZone = "America/New_York";
      time.timeZone = "America/Chicago";

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
        usbutils
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
          "/home/${username}/.ssh/id_ed25519"
        ];
        secrets = {
          root_password.file = ../../secrets/root_password.age;
          quil_password.file = ../../secrets/quil_password.age;
        };
      };

      # default user settings regardless of host/user
      users = {
        defaultUserShell = pkgs.zsh;
        users = {
          root.hashedPasswordFile = config.age.secrets.root_password.path;
          ${username} = {
            isNormalUser = true;
            hashedPasswordFile = config.age.secrets.quil_password.path;
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
        stateVersion = "26.11"; # KEEP THIS THE SAME
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

      nixpkgs.config = {
        allowUnfree = true;
      };
      nix = {
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 1w";
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

  # Host traits; read by shared modules as the `tags` specialArg.
  configurations.nixos.snowflake.tags = [ "laptop" "asus" ];
}

{ topConfig, ... }:
{
  # Shared base for the personal machines (snowflake, moraine). Per-host
  # specifics — hardware, disko, host-only packages — stay in system/<host>/.
  flake.nixosModules.workstation =
    {
      pkgs,
      lib,
      inputs,
      username,
      system,
      config,
      ...
    }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        topConfig.flake.nixosModules.security
      ];

      # --- Boot ---
      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        loader = {
          systemd-boot.enable = false;
          efi.canTouchEfiVariables = true;
          grub = {
            enable = true;
            device = "nodev"; # EFI-only: never write a BIOS MBR
            configurationLimit = 5;
            efiSupport = true;
          };
        };
      };

      networking = {
        networkmanager = {
          enable = true;
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

      time.timeZone = "America/Chicago";

      # default packages regardless of user/host
      environment.systemPackages = with pkgs; [
        appimage-run
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
          root_password.file = ../../../secrets/root_password.age;
          quil_password.file = ../../../secrets/quil_password.age;
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
              (builtins.readFile ../../keys/id_snowflake.pub)
            ];
          };
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
}

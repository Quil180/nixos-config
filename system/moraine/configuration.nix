{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.moraine.module =
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
        moraine_hardware
        moraine_disko
        security

        # --- Hardware Support ---
        amd

        # --- Desktop Environment & Display Manager ---
        hyprland
        sddm

        # --- System Services ---
        sound
        bluetooth

        # --- Applications & Gaming ---
        games

        # --- Wired but disabled (mirrors snowflake/configuration.nix) ---
        # cinnamon
        # dwm
        # ly
        # monitoring
        # docker
        # virtualisation  # virt-manager/QEMU stack (libvirt guest host) — snowflake only
        # hamachi
        tailscale
        # zerotier
        # kiwix
        # teamviewer
        # vncviewer
        # ollama
        # llamacpp
        # openwebui
        # determinate
        # persist
        # proxmox_vm
        # simple_disko
      ];

      # --- Boot (host-local: snowflake gets its bootloader from g14.nix) ---
      # RX 9070 XT is RDNA4 and Zen 4 wants recent CPPC/amdgpu support, hence
      # linuxPackages_latest. Swap to grub here if preferred.
      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        kernelParams = [
          "amd_pstate=active" # Zen 4 pstate driver
        ];
        loader = {
          systemd-boot.enable = false;
          grub = {
            enable = true;
            device = "nodev"; # EFI-only: never write a BIOS MBR
            configurationLimit = 5;
            efiSupport = true;
          };
          efi.canTouchEfiVariables = true;
        };
      };

      networking = {
        hostName = "moraine";
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

      hardware.enableAllFirmware = true;
      hardware.enableRedistributableFirmware = true;

      time.timeZone = "America/Chicago";

      environment.systemPackages = with pkgs; [
        appimage-run
        btop
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

      system.stateVersion = "26.11"; # KEEP THIS THE SAME

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
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
        };
        nix-ld.enable = true;
        zsh.enable = true;
      };

      services = {
        openssh.enable = true;
        printing.enable = true;
        devmon.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;
        pcscd.enable = true;
        gnome.gnome-keyring.enable = true;
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
  configurations.nixos.moraine.tags = [ "desktop" ];
}

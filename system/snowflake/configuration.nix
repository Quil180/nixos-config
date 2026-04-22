{ topConfig, lib, pkgs, ... }:
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
  imports = [ topConfig.flake.nixosModules.snowflake_hardware topConfig.flake.nixosModules.disko topConfig.flake.nixosModules.determinate topConfig.flake.nixosModules.secrets topConfig.flake.nixosModules.persist topConfig.flake.nixosModules.amd topConfig.flake.nixosModules.sddm topConfig.flake.nixosModules.dwm topConfig.flake.nixosModules.hyprland topConfig.flake.nixosModules.cinnamon topConfig.flake.nixosModules.sound topConfig.flake.nixosModules.bluetooth topConfig.flake.nixosModules.security topConfig.flake.nixosModules.virtualisation topConfig.flake.nixosModules.games topConfig.flake.nixosModules.hamachi topConfig.flake.nixosModules.zerotier topConfig.flake.nixosModules.docker topConfig.flake.nixosModules.flatpak topConfig.flake.nixosModules.g14 topConfig.flake.nixosModules.kiwix topConfig.flake.nixosModules.ollama topConfig.flake.nixosModules.llamacpp topConfig.flake.nixosModules.teamviewer topConfig.flake.nixosModules.vncviewer topConfig.flake.nixosModules.winboat ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    resumeDevice = "/dev/mapper/root_vg-root";
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        configurationLimit = 5;
        device = "nodev";
        efiSupport = true;
      };
    };
    kernelModules = [
      "ip_tables"
      "iptable_nat"
    ];
    # Using the latest kernel is recommended for Asus Rog Zephyrus G14 (GA402) support
    # This provides the necessary drivers and patches for this hardware.
    # To compile the specific linux-g14 kernel instead, check system/universal/g14/g14.nix
    kernelPackages = pkgs.linuxPackages_latest;
  };

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

  age.secrets.snowflake = {
    file = ../../secrets/snowflake.age;
    path = "/home/${username}/.ssh/id_snowflake";
    owner = username;
    mode = "600";
  };
  age.secrets.luks.file = ../../secrets/luks.age;
  age.secrets.quil_password.file = ../../secrets/quil_password.age;
  age.secrets.github_token = {
    file = ../../secrets/github_token.age;
    owner = username;
  };
  age.secrets.git_identity = {
    file = ../../secrets/git_identity.age;
    owner = username;
  };

  # default user settings regardless of host/user
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = true;
    users.${username} = {
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
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
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
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];

    };
  };
}
;
}

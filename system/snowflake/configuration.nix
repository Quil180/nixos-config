{pkgs, inputs, ...}: {
  imports = [
    # importing sops for secrets management systemwide
    ./hardware-configuration.nix
    ./disko.nix
    # ./secrets.nix

    # gpu support
    ../universal/gpu-support/amd.nix

    # optional stuff
    # System GUI I want (if any):
    ../universal/hyprland.nix

    # Sound?
    ../universal/sound.nix

    # Game Applications setup/installed?
    ../universal/games.nix

    # Extra options...
    ../universal/g14/g14.nix
    ../universal/hamachi.nix
    ../universal/persist.nix
    ../universal/virtualisation.nix
    ../universal/docker.nix
    ../universal/flatpak/flatpak.nix
    ../universal/vncviewer.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };
  };

  networking = {
    hostName = "snowflake";
    networkmanager.enable = true;
  };

  time.timeZone = "America/New_York";

  # default packages regardless of user/host
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    git
    gh
    neovim
    sops
    ranger
    wget
    zsh
  ];

  fonts.packages = with pkgs; [
    font-awesome
    font-awesome_5
    font-awesome_4
    powerline-fonts
    nerd-fonts.iosevka
    nerd-fonts.symbols-only
  ];

  # default user settings regardless of host/user
  users = {
    defaultUserShell = pkgs.zsh;
    users.quil = {
      isNormalUser = true;
      initialPassword = "1234";
      extraGroups = [
        "networkmanager"
        "wheel"
        "storage"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../keys/id_snowflake.pub)
      ];
    };
  };

  system = {
    stateVersion = "24.05"; # KEEP THIS THE SAME
    # auto updates
    autoUpgrade = {
      enable = true;
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
    zsh.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
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
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2w";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}

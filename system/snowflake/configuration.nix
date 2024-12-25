{ config, lib, pkgs, inputs, outputs, ... }:
{
  imports = [
    # importing sops for secrets management systemwide
    inputs.sops-nix.nixosModules.sops

    ./hardware-configuration.nix
    ./disko.nix

    # optional stuff
    # GUI I want (if any):
    ../universal/hyprland.nix
    # Sound?
    ../universal/sound.nix
    # Game Applications setup/installed?
    ../universal/games.nix
    # Extra options...
    ../universal/g14.nix
    ../universal/sops.nix
    ../universal/persist.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        useOSProber = true;
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
  sops.secrets.quil-password.neededForUsers = true;
  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    users.quil = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.quil-password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      openssh.authorizedKeys.keys = [
        (builtins.readFile ../keys/id_snowflake.pub)
      ];
    };
  };

  system.stateVersion = "24.05"; # KEEP THIS THE SAME

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
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = (_: true);
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


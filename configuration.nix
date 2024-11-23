# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports = [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = false;
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
	      device = "nodev";
	      useOSProber = true;
	      efiSupport = true;
      };
    };
  };

  networking.hostName = "nixos-quil"; # Define your hostname.

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.quil = {
    isNormalUser = true;
    description = "Quil";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    fastfetch
    ranger
    git
    gh
    wget
    zsh
    
    # audio support
    pulseaudioFull
    plasma-pa

    # desktop environments
    sddm
    hyprland

    # misc things that have to be system wide
    steam
    lutris

    # G14 specific packages
    asusctl
  ];

  # Enable the OpenSSH daemon so I can SSH
  services.openssh.enable = true;

  system.stateVersion = "24.05"; # Keep the same

  # enabling flakes support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # stylix configuration
  #stylix = {
  #  enable = true;
  #  image = ./wallpapers/goddessoflight_godofdarkness_AoB.jpg;
  #};

  # misc things
  programs.steam.enable = true;
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  # the following is for the G14 specifically for asusctl
  services.supergfxd.enable = true;
  services.asusd = {
    enable = true;
    enableUserService = true;
  };
  programs.rog-control-center.enable = true;

  # for sddm/wayland
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    enableHidpi = true;
    autoNumlock = true;
  };
  
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 2w";
  };
  nix.settings.auto-optimise-store = true;

  # sound settings
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
    	enable = true;
	support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };
}

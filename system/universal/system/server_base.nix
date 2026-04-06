{ pkgs, config, username, inputs, system, ... }:
{
  imports = [
    ../services/monitoring.nix
    ./security.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Common networking settings
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 9100 ]; # SSH and Node Exporter
    };
  };

  # Time zone
  time.timeZone = "America/New_York";

  # Common packages
  environment.systemPackages = with pkgs; [
    btop
    fastfetch
    git
    gh
    neovim
    sops
    ranger
    wget
    inputs.agenix.packages.${system}.default
  ];

  # QEMU Guest Agent for Proxmox
  services.qemuGuest.enable = true;

  age.secrets.quil_password.file = ../../../secrets/quil_password.age;

  # User configuration
  users.users.${username} = {
    isNormalUser = true;
    hashedPasswordFile = config.age.secrets.quil_password.path;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../keys/id_snowflake.pub)
    ];
  };

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}

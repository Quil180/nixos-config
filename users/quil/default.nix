{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.sop-nix.nixosModules.sops

    # GUI I want (if any):
    ../universal/hyprland.nix
    # Sound?
    ../universal/sound.nix
    # Game Applications setup/installed?
    ../universal/games.nix
    # Extra options...
    ../universal/g14.nix
  ];

  # sops for users proper
  sops.secrets.quil-password.neededForUsers = true;

  # user packages
  users = {
    mutableUsers = false; # so that sops can set passwords
    quil = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.quil-password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  # enabling the services I need system wide
  services = {
    # Enable CUPS to print documents.
    printing.enable = true;
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    validateSopsFiles = false;
    defaultSopsFormat = "yaml";

    age = {
      # automatically import host SSH keys as age key.
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/keys.txt";
      generateKey = true;
    };
  };
}

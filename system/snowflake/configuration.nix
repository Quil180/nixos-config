{ config, lib, pkgs, inputs, outputs, ... }:
{
  imports = [
    # importing sops for secrets management systemwide
    # inputs.sops-nix.nixosModules.sops

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
    mutableUsers = true; # so that sops can set passwords
    users.quil = {
      isNormalUser = true;
      initialPassword = "1234";
      # hashedPasswordFile = config.sops.secrets.quil-password.path;
      extraGroups = [
        "networkmanager"
        "wheel"
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

  # system files we want to keep
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/lib/sops-nix"
      "/etc/NetworkManager/system-connections"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    # files = [
    #   "/etc/machine-id"
    # ];
  };

  # sops for user proper
  # sops = {
  #   secrets.quil-password.neededForUsers = true;
  #   defaultSopsFile = ../../secrets/secrets.yaml;
  #   validateSopsFiles = false;
  #   defaultSopsFormat = "yaml";
  # 
  #   age = {
  #     # automatically import host SSH keys as age key.
  #     sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  #     keyFile = "/var/lib/sops-nix/keys.txt";
  #     generateKey = true;
  #   };
  # };


  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

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


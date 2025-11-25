{
  pkgs,
  inputs,
  username,
  system,
  config,
  ...
}: {
  imports = [
    # importing sops for secrets management systemwide
    ./hardware-configuration.nix
    ./disko.nix
    # ./secrets.nix

    # gpu support
    ../universal/gpu-support/amd.nix

    # optional stuff
    # System GUI I want (if any):
    # ../universal/GUI/dwm/dwm.nix
    ../universal/GUI/hyprland/hyprland.nix

    # Sound?
    ../universal/system/sound.nix
    ../universal/system/bluetooth.nix
    # ../universal/system/persist.nix
    ../universal/system/virtualisation.nix

    # Game Applications setup/installed?
    ../universal/games.nix

    # VPNs
    # ../universal/vpns/hamachi.nix
    # ../universal/vpns/zerotier.nix

    # Extra options...
    ../universal/docker.nix
    # ../universal/flatpak.nix
    ../universal/g14/g14.nix
    # ../universal/kiwix.nix
		# ../universal/ollama.nix
		../universal/teamviewer.nix
   # ../universal/vncviewer.nix
   ../universal/winboat.nix

  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
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
    # kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "snowflake";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
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
    users.${username} = {
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
    appimage = {
      enable = true;
      binfmt = true;
    };
		gnupg.agent = {
			enable = true;
			enableSSHSupport = true;
		};
		neovim = {
			# Enabling customization of neovim and nightly version
			enable = true;
			package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
      dates = "weekly";
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
}

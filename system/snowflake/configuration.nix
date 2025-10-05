{
  pkgs,
  inputs,
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
    ../universal/kiwix.nix
		# ../universal/ollama.nix
		../universal/teamviewer.nix
   # ../universal/vncviewer.nix

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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "pcie_aspm.policy=powersave"
    ];
  };

  networking = {
    hostName = "snowflake";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
		firewall = {
			enable = false;
		};
  };
  # To ensure all firmware is loaded
  hardware.enableRedistributableFirmware = true;

  time.timeZone = "America/New_York";

  # default packages regardless of user/host
  environment.systemPackages = with pkgs; [
    btop-rocm
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
        "video"
				"kvm"
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
		gnupg.agent = {
			enable = true;
			enableSSHSupport = true;
		};
		neovim = {
			# Enabling customization of neovim and nightly version
			enable = true;
			package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

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

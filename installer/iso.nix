# NixOS installer ISO
#
# Builds a bootable ISO that carries your whole dotfiles repository and can
# install the configured host onto a target drive in a single command:
#
#   nix build .#nixosConfigurations.installer.config.system.build.isoImage
#   sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
#
# Boot the ISO, and at the root shell run:
#
#   nixos-install-drive
#
# Everything the installer needs (your repo, disko, nmcli, nixos-install) is
# bundled, so only the actual system/home builds need network.
{
  config,
  lib,
  pkgs,
  inputs,
  flakeSource,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.installer = {
    # Which NixOS configuration to install (must exist in system/<name>/disko.nix)
    system = lib.mkOption {
      type = lib.types.str;
      default = "snowflake";
      description = "NixOS configuration name to install from this ISO.";
    };
    # Which home-manager user configuration to install
    user = lib.mkOption {
      type = lib.types.str;
      default = "quil";
      description = "Home-manager user configuration name to install.";
    };
    # Only used for display/confirmation in the installer prompt; the actual
    # device disko wipes comes from system/<name>/disko.nix. Keep in sync.
    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/nvme0n1";
      description = "Target disk (informational; disko.nix is authoritative).";
    };
    # If true, run the installer automatically on tty2 at boot with --yes.
    # Wipes the target disk without interaction — enable deliberately.
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start the installer at boot (destructive).";
    };
  };

  config = {
    # Bootable from a USB stick (hybrid ISO).
    isoImage.makeUsbBootable = lib.mkDefault true;

    # Bundle the dotfiles flake (minus .git) into the ISO at /root/dotfiles.
    # This is the flake the installer builds from — pinned by flake.lock.
    isoImage.contents = [
      {
        source = flakeSource;
        target = "/root/dotfiles";
      }
    ];

    # Everything the installer orchestrator needs, plus the `install`
    # command bound to the configured defaults.
    environment.systemPackages = [
      inputs.disko.packages.${system}.disko
      pkgs.nixos-install-tools # nixos-install, nixos-enter
      pkgs.git
      pkgs.curl
      pkgs.util-linux # lsblk
      pkgs.networkmanager # nmcli
      (pkgs.writeShellScriptBin "nixos-install-drive" ''
        export NIXOS_INSTALL_SYSTEM="${config.installer.system}"
        export NIXOS_INSTALL_USER="${config.installer.user}"
        export NIXOS_INSTALL_DEVICE="${config.installer.device}"
        export NIXOS_INSTALL_FLAKE=/root/dotfiles
        exec /root/dotfiles/installer/install.sh "$@"
      '')
    ];

    # Networking is required (builds fetch from cache.nixos.org), and nmcli is
    # the fallback when there is no wired connection.
    networking.networkmanager.enable = true;

    # So `nix build/eval <path>#...` works without extra flags.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Land directly in a root shell.
    services.getty.autologinUser = lib.mkDefault "root";
    users.users.root.initialHashedPassword = "";

    # Show what to do on every root login.
    system.activationScripts.installerBanner = lib.stringAfter [ "etc" ] ''
      cat > /root/.bashrc <<'BANNER'
      export PATH="/root/.nix-profile/bin:$PATH"

      echo ""
      echo "  NixOS installer for '${config.installer.system}'"
      echo "  -------------------------------------------------------------"
      echo "  To install onto ${config.installer.device} run:"
      echo "      nixos-install-drive"
      echo "  This will COMPLETELY ERASE ${config.installer.device}."
      echo "  (options: --yes, --device /dev/sdX, --system NAME, --user NAME)"
      echo ""
    BANNER
    '';

    # Optionally run the whole thing unattended at boot (tty2, so the root
    # shell on tty1 stays available).
    systemd.services.nixos-install-drive = lib.mkIf config.installer.autoStart {
      description = "Automated NixOS install onto ${config.installer.device}";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        StandardInput = "tty";
        StandardOutput = "tty";
        TTYPath = "/dev/tty2";
        TTYReset = true;
        TTYVTDisallocate = true;
      };
      script = ''
        echo "Starting automated installer (tty2)..." > /dev/tty2
        /run/current-system/sw/bin/nixos-install-drive --yes
        echo "Installer finished." > /dev/tty2
      '';
    };
  };
}
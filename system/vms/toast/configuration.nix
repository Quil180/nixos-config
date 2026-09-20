{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.toast.module =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [ lxc_base lan_access ];

      networking.hostName = "toast";
      system.stateVersion = "26.11";

      # ---- Jellyfin.
      services.jellyfin = {
        enable = true;
        openFirewall = false; # reached through Caddy on crust
        # The GPU arrives as a /dev/dri bind-mount from the Proxmox host
        # (server_notes note 4), NOT via vfio. The module sets the systemd
        # DeviceAllow for this device itself when acceleration is on.
        hardwareAcceleration = {
          enable = true;
          type = "vaapi";
          device = "/dev/dri/renderD128";
        };
      };

      hardware.graphics = {
        enable = true;
        # Radeon RX 460 (Polaris/gfx8) passed through to the container. Mesa's
        # radeonsi provides the VAAPI driver — `libva-mesa-driver` ships inside
        # `mesa` these days, so this single package is the whole requirement.
        # The card must also be bind-mounted into the LXC from Bakery
        # (/dev/dri + cgroup device allow in the Proxmox .conf) — that part is
        # not Nix-side.
        extraPackages = with pkgs; [ mesa ];
      };

      services.lanAccess.fromCrust = [ 8096 ];

      # ---- /mnt/media from Breadbox (TrueNAS).
      fileSystems."/mnt/media" = {
        # TODO(quil): confirm the exact export path on Breadbox.
        device = "breadbox:/mnt/media";
        fsType = "nfs";
        options = [ "_netdev" "x-systemd.automount" "noauto" "nofail" ];
      };
    };

  configurations.nixos.toast.tags = [ "lxc" "server" "media" "gpu" ];
}

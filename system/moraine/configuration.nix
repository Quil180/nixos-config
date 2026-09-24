{ topConfig, ... }:
{
  configurations.nixos.moraine.module =
    { pkgs, ... }:
    {
      imports = with topConfig.flake.nixosModules; [
        # --- Core System & Hardware ---
        workstation # shared personal-machine base (boot, users, nix, services)
        moraine_hardware
        moraine_disko
        wireguard_client

        # --- Hardware Support ---
        amd

        # --- Desktop Environment & Display Manager ---
        hyprland
        sddm

        # --- System Services ---
        sound
        bluetooth

        # --- Applications & Gaming ---
        games

        # --- VPNs & Networking ---
        tailscale

        # --- Wired but disabled (mirrors snowflake/configuration.nix) ---
        # cinnamon
        # dwm
        # ly
        # monitoring
        # docker
        # virtualisation  # virt-manager/QEMU stack (libvirt guest host) — snowflake only
        # hamachi
        # zerotier
        # kiwix
        # teamviewer
        # vncviewer
        # ollama
        # llamacpp
        # openwebui
        # determinate
        # persist
        # proxmox_vm
        # simple_disko
      ];

      # Bootloader + linuxPackages_latest come from `workstation`. RX 9070 XT
      # is RDNA4 and Zen 4 wants recent CPPC/amdgpu support, hence latest.
      boot.kernelParams = [
        "amd_pstate=active" # Zen 4 pstate driver
      ];

      networking.hostName = "moraine";

      environment.systemPackages = [ pkgs.btop ];

      system.stateVersion = "26.11"; # KEEP THIS THE SAME
    };

  # Host traits; read by shared modules as the `tags` specialArg.
  configurations.nixos.moraine.tags = [ "desktop" ];
}

{ topConfig, ... }:
{
  configurations.nixos.snowflake.module =
    { pkgs, ... }:
    {
      imports = with topConfig.flake.nixosModules; [
        # --- Core System & Hardware ---
        workstation # shared personal-machine base (boot, users, nix, services)
        snowflake_hardware
        disko
        netbird_client
        # simple_disko
        # determinate
        persist
        # proxmox_vm

        # --- Hardware Support ---
        amd
        g14
        cardwire

        # --- Desktop Environments & Window Managers ---
        hyprland
        # cinnamon
        # dwm

        # --- Display Managers ---
        sddm
        # ly

        # --- System Services ---
        sound
        bluetooth
        # qt5
        # monitoring

        # --- Virtualization & Containers ---
        virtualisation
        # docker

        # --- VPNs & Networking ---
        # hamachi
        # tailscale
        # zerotier

        # --- Applications & Gaming ---
        games
        # winboat
        # kiwix
        # teamviewer
        # vncviewer

        # --- AI Services ---
        hermes
        # ollama
        # llamacpp
        # openwebui
      ];

      networking = {
        hostName = "snowflake";
        networkmanager.wifi.powersave = true;
      };

      environment.systemPackages = [ pkgs.btop-rocm ];

      # Making it so that home is ACTUALLY wiped
      persist.wipeHome = true;

      system.stateVersion = "26.11"; # KEEP THIS THE SAME
    };

  # quil's home is built into this system: `upds` activates it, and there is
  # deliberately no standalone "quil@snowflake" home target.
  configurations.nixos.snowflake.integratedHome = true;

  # Host traits; read by shared modules as the `tags` specialArg.
  configurations.nixos.snowflake.tags = [
    "laptop"
    "asus"
  ];
}

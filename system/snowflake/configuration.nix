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
        wireguard_client
        # simple_disko
        # determinate
        # persist
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
        # llamacpp  # also pulls in its cardwire GPU coupling
        # openwebui
      ];

      networking = {
        hostName = "snowflake";
        networkmanager.wifi.powersave = true;
      };

      environment.systemPackages = [ pkgs.btop-rocm ];

      system.stateVersion = "26.11"; # KEEP THIS THE SAME
    };

  # Host traits; read by shared modules as the `tags` specialArg.
  configurations.nixos.snowflake.tags = [
    "laptop"
    "asus"
  ];
}

_: {
  # Joins a personal host to the homelab's NetBird network (NetBird Cloud).
  # crust is the routing peer for the LAN, and the internal domain resolves
  # through the dashboard's nameserver group, so there is nothing per-host to
  # configure. Enrol once with `netbird up`, which signs in through the
  # browser; the login persists in /var/lib/netbird.
  flake.nixosModules.netbird_client =
    {
      lib,
      config,
      options,
      username,
      ...
    }:
    {
      config = {
        # The login (and the client's keys) for each client, /var/lib/netbird
        # for the default one.
        persist.directories = lib.mapAttrsToList (
          _: client: client.dir.state
        ) config.services.netbird.clients;

        services.netbird = {
          enable = true;
          # "client": accept the LAN route crust advertises (loose reverse-path
          # filtering). mkDefault, as in vpns/tailscale.nix, so a host can
          # override it without a conflicting-definition error.
          useRoutingFeatures = lib.mkDefault "client";
        };
      }
      # The tray UI: its preferences, notification settings and stored data,
      # and its autostart. Both live in the user's home; only hosts with
      # home-manager integrated (snowflake) can declare that from here.
      // lib.optionalAttrs (options ? home-manager) {
        home-manager.users.${username} = lib.mkIf config.services.netbird.ui.enable {
          persist.directories = [
            ".config/netbird"
            ".config/NetBird"
            ".local/share/netbird"
          ];

          # Start the tray UI with the graphical session (Hyprland's session
          # runs under systemd; ~/.config/autostart is not processed there).
          systemd.user.services.netbird-ui = {
            Unit = {
              Description = "NetBird tray UI";
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = lib.getExe config.services.netbird.ui.package;
              Restart = "on-failure";
            };
            Install.WantedBy = [ "graphical-session.target" ];
          };
        };
      };
    };
}

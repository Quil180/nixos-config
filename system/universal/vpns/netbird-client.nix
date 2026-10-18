_: {
  # Joins a personal host to the homelab's NetBird network (NetBird Cloud).
  # crust is the routing peer for the LAN, and the internal domain resolves
  # through the dashboard's nameserver group, so there is nothing per-host to
  # configure. Enrol once with `netbird up`, which signs in through the
  # browser; the login persists in /var/lib/netbird.
  flake.nixosModules.netbird_client =
    { lib, config, ... }:
    {
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
    };
}

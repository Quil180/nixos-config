{ topConfig, ... }:
{
  # A NetBird routing peer for the homelab LAN: crust (primary, on Bakery) and
  # bagel (backup, on Breadbox). The control plane is NetBird Cloud, so nothing
  # here is published. Each service behind it does its own auth (server_notes
  # note 3).
  #
  # Dashboard side (not declarable from here — server_notes "NetBird Access
  # Rules" has the full list):
  #   - Networks → homelab: add both hosts as routing peers, Masquerade ON.
  #     lan_access's VPN rules on every other host match on the routers' LAN
  #     addresses (homelab.net.vpnRouterAddresses).
  #   - DNS: a nameserver group for the internal domain pointing at
  #     Crepe/Bagel's AdGuard, which rewrites it to crust.
  #   - Access control: delete the Default policy, then the policies in the
  #     notes.
  flake.nixosModules.netbird_router =
    { config, lib, ... }:
    let
      cfg = config.homelab.netbirdRouter;
      haveSetupKey = cfg.setupKey != null && builtins.pathExists cfg.setupKey;
    in
    {
      imports = [ topConfig.flake.nixosModules.homelab_net ];

      options.homelab.netbirdRouter.setupKey = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          agenix-sealed setup key for unattended enrolment. Until the file
          exists (create it from the NetBird dashboard, see secrets.nix) the
          client still runs but stays logged out, instead of failing
          evaluation.
        '';
      };

      config = {
        services.netbird = {
          # "server": IP forwarding for the routed LAN.
          useRoutingFeatures = "server";
          clients.wt0 = {
            port = 51820;
            interface = config.homelab.net.netbirdInterface;
            # Opens the WireGuard port so peers can connect directly instead of
            # through NetBird's relays. Forwarding it on Pretzel (to crust) is
            # optional, not required.
            openFirewall = true;
            login = lib.mkIf haveSetupKey {
              enable = true;
              setupKeyFile = config.age.secrets.netbird_setup_key.path;
            };
          };
        };

        # NetBird peers arrive from an address the LAN cannot route back to,
        # so strict reverse-path filtering would drop them.
        networking.firewall.checkReversePath = "loose";

        age.secrets.netbird_setup_key = lib.mkIf haveSetupKey {
          file = cfg.setupKey;
        };
      };
    };
}

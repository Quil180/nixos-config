_: {
  # ---- THE single source of truth for the homelab network -----------------
  # Everything that needs crust's address, the internal domain or a subnet
  # reads these options instead of hardcoding them. Change a value HERE and
  # every consumer follows: firewall rules, Caddy's vhosts, crust's own
  # address. Nothing else should contain these literals.
  flake.nixosModules.homelab_net =
    { lib, config, ... }:
    {
      # Stable key: lets several modules (lan_access, …)
      # import this without declaring the options twice.
      key = "dotfiles#nixosModules.homelab_net";

      options.homelab.net = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "yousef.wiki";
          description = "The domain every service is served under (Caddy vhosts are derived from it).";
        };

        crustAddress = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.5";
          description = ''
            crust's LAN address: the only source allowed to reach the service
            UIs, and the address Caddy serves the internal domain from.

            TODO(quil): PROVISIONAL home-LAN placeholder — pin crust to match
            (DHCP reservation on Pretzel, or the static profile below) and keep
            this the single value in sync.
          '';
        };

        lanPrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 24;
          description = "Prefix length for crustAddress.";
        };

        lanSubnet = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.0/24";
          description = "The LAN every host sits on.";
        };

        lanGateway = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.1";
          description = "The LAN gateway / DNS (Pretzel, pfSense).";
        };

        bagelAddress = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.6";
          description = ''
            bagel's LAN address. bagel is the backup NetBird routing peer (it
            lives on Breadbox, so it survives Bakery going down), and VPN
            traffic routed through it arrives masqueraded from this address.

            TODO(quil): PROVISIONAL — give bagel a DHCP reservation on Pretzel
            that matches this value.
          '';
        };

        vpnRouterAddresses = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            config.homelab.net.crustAddress
            config.homelab.net.bagelAddress
          ];
          defaultText = lib.literalExpression "[ crustAddress bagelAddress ]";
          description = ''
            LAN addresses of the NetBird routing peers. Both masquerade, so a
            VPN peer's traffic reaches every other host from one of these.
          '';
        };

        dmzSubnets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "192.168.20.0/24" # DMZ_GAMES, VLAN 20: waffle
            "192.168.30.0/24" # DMZ_DL, VLAN 30: croissant
          ];
          description = ''
            The DMZ VLANs on Pretzel. Hosts there can't open connections into
            the LAN except where pfSense allows it (server_notes "DMZ VLANs"),
            so anything they must reach is opened with lanAccess.fromDmz.
          '';
        };

        netbirdInterface = lib.mkOption {
          type = lib.types.str;
          default = "wt0";
          description = ''
            The NetBird interface on the routing peers (crust, bagel), the
            only way in from outside. Tunnel addresses are handed out by
            NetBird Cloud and are not stable, so the routers' firewalls trust
            this interface rather than a subnet.
          '';
        };
      };
    };
}

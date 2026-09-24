{ topConfig, ... }:
{

  # Exposes service ports to exactly the right sources.
  #
  # Everything is written as explicit IPv4 rules rather than
  # networking.firewall.allowedTCPPorts, because that option opens a port for
  # BOTH address families — and this LAN advertises a *public* IPv6 prefix
  # (2605:a601:1525:fa01::/64), so anything opened that way is reachable from
  # the internet. IPv6 is deliberately left closed for every port below.
  #
  # Design: crust's Caddy terminates TLS on the internal domain and
  # reverse-proxies to the service UIs, so the UIs are reachable from crust
  # alone. DNS and log ingestion are LAN-wide because they are consumed by
  # every host, not by a browser.
  flake.nixosModules.lan_access =
    { config, lib, ... }:
    let
      net = config.homelab.net;
      cfg = config.services.lanAccess;

      rule =
        proto: ports: src:
        lib.optionalString (ports != [ ]) ''
          iptables -A nixos-fw -p ${proto} -m multiport --dports ${
            lib.concatMapStringsSep "," toString ports
          } -s ${src} -j nixos-fw-accept
        '';
    in
    {
      # Stable key so server_base, monitoring, … can each import this safely.
      key = "dotfiles#nixosModules.lan_access";

      # Network facts come from flake.nixosModules.homelab_net — edit them THERE.
      imports = [ topConfig.flake.nixosModules.homelab_net ];

      options.homelab.expose = lib.mkOption {
        type = lib.types.attrsOf lib.types.port;
        default = { };
        example = {
          sonarr = 8989;
        };
        description = ''
          Service UIs this host serves through crust, as subdomain -> local
          port. crust's Caddy derives `https://<name>.<domain>` ->
          `<this host>:<port>` from it, and the port is opened to crust
          alone (it is added to services.lanAccess.fromCrust). Declaring a
          UI here is the whole job: no edit on crust is needed.
        '';
      };

      options.services.lanAccess = {
        fromCrust = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "TCP ports reachable only from crust, which serves them over HTTPS.";
        };
        fromLan = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "TCP ports reachable from the whole LAN (things every host consumes).";
        };
        fromLanUdp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "UDP ports reachable from the whole LAN.";
        };
        fromWireguard = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "TCP ports reachable from WireGuard clients — the only way in from outside.";
        };
        fromWireguardUdp = lib.mkOption {
          type = lib.types.listOf lib.types.port;
          default = [ ];
          description = "UDP ports reachable from WireGuard clients.";
        };
      };

      config.services.lanAccess.fromCrust = lib.attrValues config.homelab.expose;

      config.networking.firewall.extraCommands = ''
        # services.lanAccess.* — IPv4 only, by design (public IPv6 prefix on this
        # LAN). See flake.nixosModules.lan_access.
        ${rule "tcp" cfg.fromCrust net.crustAddress}
        ${rule "tcp" cfg.fromLan net.lanSubnet}
        ${rule "udp" cfg.fromLanUdp net.lanSubnet}
        ${rule "tcp" cfg.fromWireguard net.wgSubnet}
        ${rule "udp" cfg.fromWireguardUdp net.wgSubnet}
      '';
    };
}

{
  topConfig,
  ...
}:
{
  configurations.nixos.crust.module =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      # From the single source of truth (flake.nixosModules.homelab_net).
      inherit (config.homelab.net)
        domain
        crustAddress
        lanPrefixLength
        lanGateway
        ;

      # Every service UI in the homelab, collected from each server's own
      # `homelab.expose` (see lan_access): { host, sub, port } per entry.
      # Adding a UI on its host is enough — nothing here needs editing.
      servers = lib.filterAttrs (
        _: host: builtins.elem "server" host.tags
      ) topConfig.configurations.nixos;
      exposed = lib.concatLists (
        lib.mapAttrsToList (
          host: _:
          lib.mapAttrsToList (sub: port: {
            inherit host sub port;
          }) topConfig.flake.nixosConfigurations.${host}.config.homelab.expose
        ) servers
      );
      subs = map (e: e.sub) exposed;
    in
    {
      imports = with topConfig.flake.nixosModules; [ vm_base ];

      networking.hostName = "crust";
      system.stateVersion = "26.11";

      # ---- WireGuard: the only way into the network. Peers are declarative;
      #      each service behind it does its own auth (server_notes note 3).
      networking.wireguard.interfaces.wg0 = {
        ips = [ "10.10.0.1/24" ];
        listenPort = 51820;
        # Pre-generated and sealed, so the clients could be configured
        # before this host exists. The public half is in homelab-net.nix.
        privateKeyFile = config.age.secrets.wg_crust.path;

        # Derived from the mesh, so a client's tunnel address and the peer
        # entry that admits it can never disagree.
        peers = lib.mapAttrsToList (_name: c: {
          inherit (c) publicKey;
          allowedIPs = [ "${c.address}/32" ];
        }) config.homelab.net.wgClients;
      };

      # WireGuard peers arrive from an address the LAN cannot route back to,
      # so strict reverse-path filtering would drop them.
      networking.firewall.checkReversePath = "loose";

      # ---- Internal DNS for tunnel clients. The LAN's AdGuard rewrite only
      #      helps LAN clients; a VPN client has no way to resolve the
      #      internal domain otherwise, and without a hostname Caddy cannot
      #      pick a vhost. Answers the internal zone locally, forwards the
      #      rest upstream. Reachable on wg0 only.
      services.dnsmasq = {
        enable = true;
        settings = {
          port = 53;
          address = [ "/${domain}/${crustAddress}" ];
          server = [
            lanGateway
            "1.1.1.1"
          ];
          no-resolv = true;
          interface = "wg0";
          # bind-dynamic, not bind-interfaces: the latter binds wg0's address
          # at startup and fails outright if the interface does not exist yet,
          # which makes dnsmasq's start order against WireGuard matter.
          # bind-dynamic tolerates the interface appearing later.
          "bind-dynamic" = true;
        };
      };

      # ---- Pinned LAN address -----------------------------------------------
      # Declared from the single source of truth, so changing crust's address
      # means editing homelab.net.crustAddress and nothing else. Scripted
      # networking (what proxmox_vm uses), not a NetworkManager profile —
      # NetworkManager is not enabled on the servers.
      #
      # The alternative is a DHCP reservation on Pretzel, which needs no
      # interface name: in that case delete this block and just keep
      # homelab.net.crustAddress in sync.
      #
      # NOTE: `ens18` is Proxmox's default virtio NIC name — confirm with
      # `ip -br link` on first boot and change it here if yours differs. If it
      # matches nothing, crust comes up with no IPv4 address at all; the
      # Proxmox console still works to fix it.
      networking = {
        useDHCP = false;
        interfaces.ens18 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = crustAddress;
              prefixLength = lanPrefixLength;
            }
          ];
        };
        defaultGateway = lanGateway;
        nameservers = [ lanGateway ];
        search = [ domain ];
        # IPv6 stays on SLAAC from the router's advertisements (kernel default).
      };

      # The WireGuard port is the one thing that must be reachable from the
      # internet; everything else rides the tunnel.
      networking.firewall.allowedUDPPorts = [ 51820 ];

      # Caddy is the single authenticated front door for the internal domain.
      # Reachable from WireGuard clients (the intended path) and from the LAN,
      # so LAN-side consumers — the homepage dashboard's widgets, your own
      # browser — can use https://<service>.<domain> too. Neither rule includes
      # the world, and IPv6 stays closed, so nothing is published.
      services.lanAccess = {
        fromWireguard = [
          80
          443
          53
        ];
        fromWireguardUdp = [ 53 ];
        fromLan = [
          80
          443
        ];
      };

      # ---- Caddy: TLS for every service on the internal domain.
      #      DNS-01 is mandatory — there is no public HTTP-01 path on a
      #      WireGuard-only network (server_notes), so the porkbun plugin is
      #      compiled in and the API credentials come from agenix.
      services.caddy = {
        enable = true;

        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/porkbun@v0.3.1" ];
          # Obtained via the fakeHash workflow; changes if you bump the plugin.
          hash = "sha256-iFuoa6k2r3jUPazHHujhB4bBq3Fz0Mv0Tjsr+gxMYQQ=";
        };

        # Declared once globally so every vhost below uses DNS-01.
        # The ACME contact address is substituted from the agenix env file
        # rather than written here, so the real mailbox stays out of the repo.
        globalConfig = ''
          acme_dns porkbun {
            api_key {env.PORKBUN_API_KEY}
            api_secret_key {env.PORKBUN_API_SECRET_KEY}
          }
          email {$ACME_EMAIL}
        '';

        # KEY=value file, sealed with agenix: the Porkbun API key/secret and
        # ACME_EMAIL. Nothing credential-ish lives in this file.
        environmentFile = config.age.secrets.caddy_porkbun_env.path;

        # Derived from every server's homelab.expose (see `exposed` above).
        virtualHosts = lib.listToAttrs (
          map (
            e:
            lib.nameValuePair "${e.sub}.${domain}" {
              extraConfig = "reverse_proxy ${e.host}:${toString e.port}";
            }
          ) exposed
        );
      };

      age = {
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.caddy_porkbun_env.file = ../../../secrets/caddy_porkbun_env.age;
        secrets.wg_crust.file = ../../../secrets/wg_crust.age;
      };

      # Nothing is exposed publicly — only wg clients reach Caddy.
      services.caddy.openFirewall = false;

      # Two hosts claiming the same subdomain would silently shadow one
      # another in the vhost set above; fail the build instead.
      assertions = [
        {
          assertion = lib.allUnique subs;
          message = "homelab.expose: subdomain claimed by more than one host: ${
            toString (lib.filter (x: lib.count (y: y == x) subs > 1) (lib.unique subs))
          }";
        }
      ];
    };

  configurations.nixos.crust.tags = [
    "vm"
    "server"
    "gateway"
  ];
}

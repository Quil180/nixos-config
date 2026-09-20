{
  topConfig,
  lib,
  pkgs,
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
      inherit (config.homelab.net) domain crustAddress lanPrefixLength lanGateway;
    in
    {
      imports = with topConfig.flake.nixosModules; [ vm_base lan_access ];

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
        peers = lib.mapAttrsToList (name: c: {
          publicKey = c.publicKey;
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
          server = [ lanGateway "1.1.1.1" ];
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
      # means editing homelab.net.crustAddress and nothing else.
      #
      # The alternative is a DHCP reservation on Pretzel, which needs no
      # interface name: in that case delete this profile and just keep
      # homelab.net.crustAddress in sync.
      #
      # NOTE: `ens18` is Proxmox's default virtio NIC name — confirm with
      # `ip -br link` on first boot and change it here if yours differs. The
      # failure mode is gentle: a profile that matches nothing leaves
      # NetworkManager on the DHCP profile, so crust stays reachable, it just
      # won't hold the pinned address (and the crust-scoped rules won't match).
      networking.networkmanager.ensureProfiles.profiles.lan = {
        connection = {
          id = "lan";
          type = "ethernet";
          interface-name = "ens18";
          autoconnect = true;
          # Beat the DHCP profile proxmox_vm generates, or NM may pick that.
          autoconnect-priority = 100;
        };
        ipv4 = {
          method = "manual";
          address1 = "${crustAddress}/${toString lanPrefixLength},${lanGateway}";
          dns = lanGateway;
          dns-search = domain;
        };
        ipv6.method = "auto";
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
        fromWireguard = [ 80 443 53 ];
        fromWireguardUdp = [ 53 ];
        fromLan = [ 80 443 ];
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

        virtualHosts = {
          "gitea.${domain}" = { extraConfig = "reverse_proxy scone:3000"; };
          "home.${domain}" = { extraConfig = "reverse_proxy scone:8082"; };
          "qbit.${domain}" = { extraConfig = "reverse_proxy croissant:8080"; };
          "sonarr.${domain}" = { extraConfig = "reverse_proxy croissant:8989"; };
          "radarr.${domain}" = { extraConfig = "reverse_proxy croissant:7878"; };
          "prowlarr.${domain}" = { extraConfig = "reverse_proxy croissant:9696"; };
          "bazarr.${domain}" = { extraConfig = "reverse_proxy croissant:6767"; };
          "paperless.${domain}" = { extraConfig = "reverse_proxy biscuit:28981"; };
          "grafana.${domain}" = { extraConfig = "reverse_proxy muffin:3000"; };
          "jellyfin.${domain}" = { extraConfig = "reverse_proxy toast:8096"; };
          "vault.${domain}" = { extraConfig = "reverse_proxy macaron:8222"; };
          "dns.${domain}" = { extraConfig = "reverse_proxy crepe:3000"; };
          "dns2.${domain}" = { extraConfig = "reverse_proxy bagel:3000"; };
        };
      };

      age = {
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.caddy_porkbun_env.file = ../../../secrets/caddy_porkbun_env.age;
        secrets.wg_crust.file = ../../../secrets/wg_crust.age;
      };

      # Nothing is exposed publicly — only wg clients reach Caddy.
      services.caddy.openFirewall = false;
    };

  configurations.nixos.crust.tags = [ "vm" "server" "gateway" ];
}

{
  topConfig,
  ...
}:
{
  configurations.nixos.bagel.module =
    {
      config,
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [ lxc_base ];

      networking.hostName = "bagel";
      system.stateVersion = "26.11";

      # ---- AdGuard Home (SECONDARY DNS). Lives on Breadbox.
      # NOTE: AdGuard has no built-in config sync between instances. If you want
      # crepe and bagel to stay in step, that needs adguardhome-sync (not in
      # nixpkgs — would be an OCI container or a systemd timer pulling the
      # primary's config over the wg network).
      services.adguardhome = {
        enable = true;
        host = "0.0.0.0";
        port = 3000;
        # Not openFirewall: that opens the web UI to every source, including
        # the internet over the public IPv6 prefix. DNS and the UI are scoped
        # separately below.
        openFirewall = false;
        mutableSettings = true;

        # Declared so the rewrite is enforced on every service start: with
        # mutableSettings = true the module yaml-MERGES this into the existing
        # config, so Nix owns the keys declared here and the web UI owns
        # everything else (filter lists, clients, upstreams). That means this
        # follows homelab.net.crustAddress automatically — change it there and
        # restart, no UI edit needed.
        settings.filtering.rewrites = [
          {
            domain = "*.${config.homelab.net.domain}";
            answer = config.homelab.net.crustAddress;
            enabled = true;
          }
        ];
      };
      # DNS serves the whole LAN (that is its job) — over both transports,
      # since resolvers fall back to TCP for large answers. The web UI is a UI,
      # so it goes through crust's Caddy.
      services.lanAccess = {
        fromLan = [ 53 ];
        fromLanUdp = [ 53 ];
      };
      homelab.expose.dns2 = 3000;
    };

  configurations.nixos.bagel.tags = [
    "lxc"
    "server"
    "dns"
    "secondary"
  ];
}

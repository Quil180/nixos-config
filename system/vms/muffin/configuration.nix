{
  topConfig,
  ...
}:
{
  configurations.nixos.muffin.module =
    {
      lib,
      config,
      ...
    }:
    let
      inherit (config.homelab.net) domain;

      # Every server runs node_exporter:9100 via server_base -> `monitoring`,
      # so the target list is every host tagged "server" — a new VM/LXC is
      # scraped with no edit here.
      nodeTargets = lib.mapAttrsToList (name: _: "${name}:9100") (
        lib.filterAttrs (_: host: builtins.elem "server" host.tags) topConfig.configurations.nixos
      );
    in
    {
      imports = with topConfig.flake.nixosModules; [ lxc_base ];

      networking.hostName = "muffin";
      system.stateVersion = "26.11";

      # ---- Prometheus.
      services.prometheus = {
        enable = true;
        port = 9090;
        retentionTime = "30d";
        globalConfig.scrape_interval = "30s";
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [ { targets = nodeTargets; } ];
          }
        ];
      };

      # ---- Loki: the log store every host ships to via Alloy.
      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_address = "0.0.0.0";
            http_listen_port = 3100;
            grpc_listen_port = 9095;
          };
          common = {
            path_prefix = "/var/lib/loki";
            replication_factor = 1;
            ring.kvstore.store = "inmemory";
            storage.filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
          };
          schema_config.configs = [
            {
              from = "2024-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
          limits_config.retention_period = "30d";
          compactor = {
            working_directory = "/var/lib/loki/compactor";
            retention_enabled = true;
            delete_request_store = "filesystem";
          };
        };
      };

      # ---- Grafana.
      services.grafana = {
        enable = true;
        openFirewall = false; # fronted by Caddy on crust
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            # Derived so alert links and redirects point at what Caddy serves.
            domain = "grafana.${domain}";
            root_url = "https://grafana.${domain}/";
          };
          # 26.05 dropped the built-in default for this and now asserts on it.
          # Read through Grafana's file provider from the agenix secret. The key
          # is generated, not looked up, and it encrypts datasource credentials
          # in grafana.db — so rotating it later needs a re-encrypt:
          #   grafana-cli admin data-migration encrypt-datasource-passwords
          security.secret_key = "$__file{${config.age.secrets.grafana_secret_key.path}}";
        };
      };

      age = {
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        # Grafana reads this itself (the $__file provider above), not via a
        # root-run systemd directive, so it must own it.
        secrets.grafana_secret_key = {
          file = ../../../secrets/grafana_secret_key.age;
          owner = "grafana";
        };
      };

      # Loki is pushed to by *every* host's Alloy, so it is LAN-wide; Grafana
      # is a UI, so it goes through crust's Caddy. Prometheus stays local (only
      # Grafana reads it).
      services.lanAccess.fromLan = [ 3100 ];
      homelab.expose.grafana = 3000;
    };

  configurations.nixos.muffin.tags = [
    "lxc"
    "server"
    "observability"
  ];
}

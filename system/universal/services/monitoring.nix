{ topConfig, ... }:
{
  flake.nixosModules.monitoring =
    { pkgs, config, ... }:
    let
      # NOTE: services.promtail no longer exists in nixpkgs — Grafana Alloy is
      # its successor. This is the Alloy equivalent of the promtail config that
      # used to be commented out here.
      alloyConfig = pkgs.writeText "alloy-config.alloy" ''
        logging {
          level = "warn"
        }

        loki.relabel "journal" {
          forward_to = []
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
        }

        loki.source.journal "journal" {
          forward_to    = [loki.write.default.receiver]
          relabel_rules = loki.relabel.journal.rules
          labels        = {
            job  = "systemd-journal",
            host = "${config.networking.hostName}",
          }
        }

        loki.write "default" {
          endpoint {
            url = "http://muffin:3100/loki/api/v1/push"
          }
        }
      '';
    in
    {
      imports = [ topConfig.flake.nixosModules.lan_access ];

      services.prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };

      services.alloy = {
        enable = true;
        configPath = alloyConfig;
      };

      # muffin's Prometheus scrapes every host. IPv4 LAN only (see lan_access)
      # — muffin has no pinned address to scope this to yet.
      services.lanAccess.fromLan = [ 9100 ];

      # Reading /var/log/journal needs the systemd-journal group.
      systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
    };
}

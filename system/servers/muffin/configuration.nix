{ pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../universal/system/server_base.nix
  ];

  boot.loader.systemd-boot.enable = pkgs.lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = pkgs.lib.mkForce false;

  networking.hostName = "muffin";

  services.prometheus = {
    enable = true;
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "nixos-nodes";
        static_configs = [
          { targets = [ "crust:9100" "baguette:9100" "scone:9100" "pancake:9100" "croissant:9100" "biscotti:9100" "macaron:9100" "muffin:9100" ]; }
        ];
      }
    ];
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
      };
      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
      };
      schema_config.configs = [{
        from = "2020-10-24";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];
    };
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security.secret_key = "PLEASE_CHANGE_ME_SOON"; # placeholder
    };
  };

  networking.firewall.allowedTCPPorts = [ 9090 3000 3100 ]; # Prometheus, Grafana, Loki
}

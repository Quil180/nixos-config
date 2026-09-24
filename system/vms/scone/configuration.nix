{
  topConfig,
  ...
}:
{
  configurations.nixos.scone.module =
    {
      config,
      ...
    }:
    let
      inherit (config.homelab.net) domain;
    in
    {
      imports = with topConfig.flake.nixosModules; [ vm_base ];

      networking.hostName = "scone";
      system.stateVersion = "26.11";

      # ---- Gitea. Local postgres; SQLite would be fine at this scale but
      #      postgres avoids the migration pain later.
      services.gitea = {
        enable = true;
        # Default backend (sqlite) is fine at this scale. NOTE: the module has
        # no `createLocally` — to move to a local postgres later use:
        #   database = { type = "postgres"; createDatabase = true; };
        settings = {
          server = {
            # Derived, not hardcoded — Gitea bakes these into clone URLs,
            # webhooks and OAuth redirects, so they must match what Caddy serves.
            DOMAIN = domain;
            ROOT_URL = "https://gitea.${domain}/";
            HTTP_PORT = 3000;
          };
          service.DISABLE_REGISTRATION = true;
          # NOTE: never set settings.repository.ROOT by hand — the module
          # derives it from its stateDir and a second definition is a
          # conflicting-definition error. To relocate repos onto /mnt/git_lfs,
          # change the module's own option, not this leaf.
        };
        # Large repos live on Breadbox; see the NFS mount below.
        lfs.enable = true;
      };

      # ---- Homepage dashboard.
      services.homepage-dashboard = {
        enable = true;
        openFirewall = false; # reached through Caddy on crust
        settings = {
          title = "homelab";
        };
        services = [
          # TODO(quil): wire the widget keys once each service has an API token
          # (tokens belong in an agenix secret + environmentFiles).
          {
            "Core" = [
              {
                "Gitea" = {
                  icon = "gitea.png";
                  href = "https://gitea.${domain}";
                  description = "git";
                };
              }
            ];
          }
        ];
      };

      # Both UIs are reached through crust's Caddy over the internal domain.
      homelab.expose = {
        gitea = 3000;
        home = 8082;
      };

      # ---- /mnt/git_lfs from Breadbox (TrueNAS).
      fileSystems."/mnt/git_lfs" = {
        # TODO(quil): confirm the exact export path on Breadbox.
        device = "breadbox:/mnt/git_lfs";
        fsType = "nfs";
        options = [
          "_netdev"
          "x-systemd.automount"
          "noauto"
          "nofail"
        ];
      };
    };

  configurations.nixos.scone.tags = [
    "vm"
    "server"
    "git"
  ];
}

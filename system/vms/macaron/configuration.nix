{
  topConfig,
  ...
}:
{
  configurations.nixos.macaron.module =
    {
      config,
      ...
    }:
    let
      inherit (config.homelab.net) domain;
    in
    {
      imports = with topConfig.flake.nixosModules; [ lxc_base ];

      networking.hostName = "macaron";
      system.stateVersion = "26.11";

      # ---- Vaultwarden: your own vault, so a Bitwarden Premium account is not
      #      the only copy of your passwords/2FA.
      services.vaultwarden = {
        enable = true;
        dbBackend = "sqlite"; # plenty at this scale (server_notes)
        # Must live OUTSIDE /var/lib/vaultwarden or the module asserts.
        # TODO(quil): point this at Breadbox (/mnt/backups) once mounted.
        backupDir = "/var/backup/vaultwarden";
        config = {
          # Vaultwarden puts this in invite/reset emails and the web-vault
          # URL, so it must match Caddy's hostname.
          DOMAIN = "https://vault.${domain}";
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = 8222;
          SIGNUPS_ALLOWED = false;
        };
        # ADMIN_TOKEN + SMTP_* come from agenix as environment variables, so
        # neither the admin token nor the mail password is in the repo.
        environmentFile = config.age.secrets.vaultwarden_env.path;
      };

      age = {
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.vaultwarden_env.file = ../../../secrets/vaultwarden_env.age;
      };

      # UI goes through crust's Caddy over HTTPS — never exposed directly.
      homelab.expose.vault = 8222;
    };

  configurations.nixos.macaron.tags = [
    "lxc"
    "server"
    "vault"
  ];
}

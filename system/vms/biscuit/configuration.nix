{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.biscuit.module =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [ vm_base lan_access ];

      networking.hostName = "biscuit";
      system.stateVersion = "26.11";

      # ---- Paperless-ngx (app + postgres + redis via the module).
      services.paperless = {
        enable = true;
        address = "0.0.0.0";
        port = 28981;
        dataDir = "/var/lib/paperless";
        mediaDir = "/var/lib/paperless/media";
        # The NAS share is the consume + media location (server_notes).
        consumptionDir = "/mnt/documents/consume";
        consumptionDirIsPublic = true;
        # Superuser is `admin` (the module default) with the password from
        # this agenix secret. The module loads it as a systemd credential and
        # creates/updates the superuser on start.
        passwordFile = config.age.secrets.paperless_admin.path;
        settings = {
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_TIME_ZONE = "America/Chicago";
          PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
        };
      };

      age = {
        # Servers decrypt with their own SSH host key — the user's private key
        # never lands on them (the serverKeys model).
        # TODO(quil): this secret is currently sealed to your user key, so run
        # the rekey step (README §4) after installing biscuit.
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets.paperless_admin.file = ../../../secrets/paperless_admin.age;
      };

      services.lanAccess.fromCrust = [ 28981 ];

      # ---- /mnt/documents from Breadbox (TrueNAS).
      fileSystems."/mnt/documents" = {
        # TODO(quil): confirm the exact export path on Breadbox.
        device = "breadbox:/mnt/documents";
        fsType = "nfs";
        options = [ "_netdev" "x-systemd.automount" "noauto" "nofail" ];
      };
    };

  configurations.nixos.biscuit.tags = [ "vm" "server" "documents" ];
}

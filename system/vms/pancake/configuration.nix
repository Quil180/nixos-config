{
  topConfig,
  ...
}:
{
  configurations.nixos.pancake.module =
    {
      config,
      ...
    }:
    let
      inherit (config.homelab.net) domain;
    in
    {
      imports = with topConfig.flake.nixosModules; [ vm_base ];

      networking.hostName = "pancake";
      system.stateVersion = "26.11";

      # ---- Immich (app + postgres + redis via the module). No machine
      #      learning (server_notes): it was most of this VM's RAM, and without
      #      it there is no face/object/smart search.
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        port = 2283;
        # Originals, thumbnails and encoded video all live on the NAS share.
        # Postgres and redis stay on the local disk (module default) — never
        # put the database on NFS.
        mediaLocation = "/mnt/photos";
        machine-learning.enable = false;

        # Declaring settings makes Immich read its config from this file, so
        # the admin settings page becomes read-only. Set `settings = null;` to
        # manage everything from the UI instead — then also turn off
        # Administration → Machine Learning there, or the server keeps trying
        # to reach the disabled ML service.
        settings = {
          machineLearning.enabled = false;
          server.externalDomain = "https://photos.${domain}";
          # Nightly pg_dump into <mediaLocation>/backups, i.e. onto the NAS,
          # where the dataset snapshots and off-box copy pick it up.
          backup.database = {
            enabled = true;
            cronExpression = "0 02 * * *";
            keepLastAmount = 14;
          };
        };
      };

      # Don't start Immich against an empty local /mnt/photos if the NAS
      # mount is missing.
      systemd.services.immich-server.unitConfig.RequiresMountsFor = [ "/mnt/photos" ];

      homelab.expose.photos = 2283;

      # ---- /mnt/photos from Breadbox (TrueNAS).
      # The immich user's uid is allocated locally, so the export must let it
      # write: on TrueNAS set the share's Mapall User/Group to the dataset's
      # owner (the module also chmods mediaLocation to 0700 on boot).
      fileSystems."/mnt/photos" = {
        # TODO(quil): confirm the exact export path on Breadbox.
        device = "breadbox:/mnt/photos";
        fsType = "nfs";
        options = [
          "_netdev"
          "x-systemd.automount"
          "noauto"
          "nofail"
        ];
      };
    };

  configurations.nixos.pancake.tags = [
    "vm"
    "server"
    "photos"
  ];
}

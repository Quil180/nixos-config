_: {
  flake.nixosModules.bluetooth = _: {
    # Paired devices.
    persist.directories = [ "/var/lib/bluetooth" ];

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings = {
          General = {
            Enable = "Source,Sink,Media,Socket";
            Experimental = true;
          };
        };
      };
    };

    services.blueman = {
      enable = true;
    };
  };
}

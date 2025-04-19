{...}: {
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    pulseaudio = {
      enable = true;
      extraConfig = ''
        load-module module-switch-on-connect
      '';
    };
  };

  services.blueman = {
    enable = true;
    autoEnable = true;
    autoEnableServices = ["bluetooth"];
  };
}

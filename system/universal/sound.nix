{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    pulseaudioFull
  ];

  # for good sound quality
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber.enable = true;
    jack.enable = true;
    pulse.enable = true;
  };
}

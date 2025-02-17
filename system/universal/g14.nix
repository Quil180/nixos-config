{pkgs, ...}: {
  boot.kernelParams = [
    "amdgpu"
  ];
  environment = {
    systemPackages = with pkgs; [
      asusctl
      pciutils
    ];
  };

  programs = {
    # G14 programs below
    rog-control-center.enable = true;
  };

  services = {
    supergfxd = {
      enable = true;
      settings = {
        mode = "Integrated";
        vfio_enable = true;
      };
    };
    asusd = {
      enable = true;
      enableUserService = true;
    };
    power-profiles-daemon.enable = true;
  };
  systemd.services.supergfxd.path = [pkgs.pciutils];
}

{pkgs, ...}: {
  boot = {
    kernelParams = [
      "amdgpu"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
  };
  environment = {
    systemPackages = with pkgs; [
      asusctl
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

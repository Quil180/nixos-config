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

  hardware = {
    graphics.enable32Bit = true;

    opengl = {
      extraPackages = with pkgs; [
        amdvlk
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
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

    xserver = {
      enable = true;
      videoDrivers = ["amdgpu"];
    };
  };
  systemd.services.supergfxd.path = [pkgs.pciutils];
}

{pkgs, ...}: {
  boot = {
    kernelParams = [
      "amdgpu"
    ];
  };

  hardware.graphics = {
    enable32Bit = true;

    extraPackages = with pkgs; [
      amdvlk
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };
}

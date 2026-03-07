{ pkgs, ... }:
{
  services = {
    xserver.enable = true;
    lact.enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    firmware = [
      pkgs.linux-firmware
    ];
    amdgpu.overdrive.enable = true;
  };

  # System packages for monitoring
  environment.systemPackages = with pkgs; [
    clinfo
  ];
}

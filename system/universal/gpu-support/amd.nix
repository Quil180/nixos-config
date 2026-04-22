{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.amd = 
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
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
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
;
}

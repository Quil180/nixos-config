{ config, lib, pkgs, inputs, ... }:
{
  boot.kernelParams = [
    "amdgpu"
  ];
  environment.systemPackages = with pkgs; [
    asusctl
  ];

  programs = {
    # G14 programs below
    rog-control-center.enable = true;
  };
  
  services = {
    supergfxd.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
}

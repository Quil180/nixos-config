{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.sddm = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.sddm
    ];

    services.displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      autoNumlock = true;
      wayland.enable = true;
    };

    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}

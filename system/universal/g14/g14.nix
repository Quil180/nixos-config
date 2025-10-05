{pkgs, ...}: {

  imports = [
    # ./kernel.nix
  ];
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];

  services = {
    # supergfxd controls GPU switching
    # Default to using iGPU. Can use CLI to enable dGPU with a logout
    supergfxd.enable = true;
    supergfxd.settings = {
      mode = "Integrated";
      vfio_enable = true;
      vfio_save = false;
      always_reboot = false;
      no_logind = false;
      logout_timeout_s = 180;
      hotplug_type = "None";
    };

    # ASUS specific software. This also installs asusctl.
    asusd = {
      enable = true;
      enableUserService = true;
    };

    # Dependency of asusd
    power-profiles-daemon.enable = true;
  };
  systemd.services.supergfxd = {
    serviceConfig = {
      KillSignal = "SIGINT";
      TimeoutStopSec = 10;
    };
    path = [pkgs.pciutils];
  };
}

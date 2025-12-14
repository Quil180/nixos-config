{pkgs, ...}: {
  imports = [
    # Uncomment the following line to compile the custom linux-g14 kernel
    ./kernel-custom.nix
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
      mode = "Hybrid";
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

    # Power Management Services
    auto-cpufreq.enable = true;
    power-profiles-daemon.enable = false;
    upower.enable = true;
  };
  systemd.services.supergfxd = {
    serviceConfig = {
      KillSignal = "SIGINT";
      TimeoutStopSec = 10;
    };
    path = [ pkgs.pciutils ];
  };

  # Power saving stuff
  boot = {
    kernelModules = ["amd-pstate"];
    kernelParams = [
      "initcall_blacklist=acpi_cpufreq_init"
      "amd_pstates=passive"
    ];
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
}

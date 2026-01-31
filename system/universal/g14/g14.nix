{pkgs, ...}: {
  imports = [
    # Uncomment the following line to compile the custom linux-g14 kernel
    # ./kernel-custom.nix
  ];
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];

  services = {
    # supergfxd controls GPU switching
    # Default to using iGPU. Can use CLI to enable dGPU with a logout
    supergfxd = {
      enable = true;
      settings = {
        mode = "Hybrid";
        vfio_enable = true;
        vfio_save = false;
        always_reboot = false;
        no_logind = false;
        logout_timeout_s = 180;
        hotplug_type = "None";
      };
    };

    # ASUS specific software. This also installs asusctl.
    asusd = {
      enable = true;
      enableUserService = true;
    };

    tlp.enable = false; # ensuring that tlp is off.
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "always"; # Max clock speeds when plugged in
        };
      };
    };
  };
  systemd.services.supergfxd = {
    serviceConfig = {
      KillSignal = "SIGINT";
      TimeoutStopSec = 10;
    };
    path = [ pkgs.pciutils ];
  };

  # Performance-optimized power settings for 6900HS/6800S
  boot = {
    kernelModules = ["amd-pstate"];
    kernelParams = [
      "initcall_blacklist=acpi_cpufreq_init"
      "amd_pstate=active" # Active mode for best performance scaling
    ];
  };

  # Ensuring that Hibernate and Suspend
  powerManagement = {
    enable = true;
  };
}

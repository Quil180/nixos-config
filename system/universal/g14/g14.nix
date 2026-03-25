{ pkgs, ... }:
{
  imports = [
    # Uncomment the following line to compile the custom linux-g14 kernel
    # ./kernel-custom.nix
  ];

  environment.systemPackages = with pkgs; [
    asusctl
  ];

  services = {
    # ASUS specific software.
    # This also installs asusctl.
    asusd = {
      enable = true;
    };

    upower.enable = true;

    tlp.enable = false;
    # ensuring that tlp is off.
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "never";
        };
      };
    };

    # Pipewire for laptop microphone
    pipewire.extraConfig.pipewire."99-echo-cancel" = {
      "context.modules" = [
        {
          name = "libpipewire-module-echo-cancel";
          args = {
            "library.name" = "aec/libspa-aec-webrtc";
            "sink.props" = {
              "node.name" = "echo-cancel-sink";
              "node.description" = "Echo Canceller (Playback)";
            };
            "source.props" = {
              "node.name" = "echo-cancel-source";
              "node.description" = "Echo Canceller (Record)";
            };
          };
        }
      ];
    };
  };

  systemd.services = {
    systemd-suspend.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
    systemd-hibernate.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
    systemd-hybrid-sleep.serviceConfig.Environment = "SYSTEMD_SLEEP_FREEZE_USER_SESSIONS=0";
  };

  # Performance-optimized power settings for 6900HS/6800S
  boot = {
    kernelModules = [ "amd-pstate" ];
    kernelParams = [
      "initcall_blacklist=acpi_cpufreq_init"
      "amd_pstate=active" # Active mode for best performance scaling
      "amdgpu.sg_display=0" # Fix for display issues on resume
      "resume_offset=533760"
      "mem_sleep_default=s2idle"
    ];
  };

  # Ensuring that Hibernate and Suspend
  powerManagement = {
    enable = true;
  };
}

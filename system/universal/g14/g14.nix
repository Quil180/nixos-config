{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.g14 =
    { pkgs, ... }:
    {
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

      systemd.tmpfiles.rules = [
        "d /etc/asusd 0755 root root -"
      ];

      # Performance-optimized power settings for 6900HS/6800S
      boot = {
        kernelModules = [ "cpuid" ];
        kernelParams = [
          "initcall_blacklist=acpi_cpufreq_init"
          "amd_pstate=active" # Active mode for best performance scaling
          "amdgpu.sg_display=0" # Fix for display issues on resume
          "amdgpu.dcdebugmask=0x10" # Fix for DCN timeouts
          "resume_offset=533760"
          "snd_hda_intel.power_save=1" # Audio power saving
          # Following are to try and optimize suspend
          "pcie_aspm=force"
        ];
        kernelPackages = pkgs.linuxPackages_latest;
        resumeDevice = "/dev/mapper/root_vg-root";
        loader = {
          systemd-boot.enable = false;
          efi = {
            canTouchEfiVariables = true;
          };
          grub = {
            enable = true;
            configurationLimit = 5;
            device = "nodev";
            efiSupport = true;
          };
        };
      };

      # Ensuring that Hibernate and Suspend
      powerManagement = {
        enable = true;
        powertop.enable = true;
      };
    };
}

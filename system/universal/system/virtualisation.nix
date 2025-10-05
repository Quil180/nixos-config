{ pkgs, ... }: 
let
	secureOVMFFull = pkgs.OVMFFull.override {
    secureBoot = true;
    tpmSupport = true;
  };
in {

	programs.dconf.enable = true;
	
  users.users.quil.extraGroups = [
		"libvirt"
		"libvirtd" 
		"kvm"
	];

  services.spice-vdagentd.enable = true;

  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
			onBoot = "ignore";
			onShutdown = "shutdown";
      qemu = {
				runAsRoot = false;
				# For Windows VMs
        ovmf = {
          enable = true;
          packages = [ secureOVMFFull ];
        };
        swtpm.enable = true;
      };
    };
  };

  environment.systemPackages = [
		# Free rdp
		pkgs.freerdp
		# Virtual-Manager GUI
    pkgs.virt-manager
    pkgs.virt-viewer
		# SPICE client for visualizations
    pkgs.spice
    pkgs.spice-gtk
    pkgs.spice-protocol
		# Drivers for Windows VM
    pkgs.win-virtio
    pkgs.win-spice
		# Icon pack for buttons
		pkgs.adwaita-icon-theme
		(pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
			qemu-system-x86_64 \
				-bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
				"$@"
		'')
  ];

	# for gpu passthrough from now on
	boot = {
		initrd = {
			availableKernelModules = [ "vfio-pci" ];
			preDeviceCommands = ''
				DEVS="0000:03:00.0 0000:03:00.1"
				for DEV in $DEVS; do
					echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
				done
				modprobe -i vfio-pci
			'';
		};
		kernelParams = [ "pcie_aspm=off" ];
		kernelModules = [ "kvm-amd" "vendor-reset" ];
	};

	environment.etc = {
		# Generally enabling hooks
		"libvirt/hooks/qemu" = {
			mode = "0755";
			text = pkgs.lib.mkForce ''
#!/usr/bin/env bash
#
# Author: Sebastiaan Meijer (sebastiaan@passthroughpo.st)
#
# Copy this file to /etc/libvirt/hooks, make sure it's called "qemu".
# After this file is installed, restart libvirt.
# From now on, you can easily add per-guest qemu hooks.
# Add your hooks in /etc/libvirt/hooks/qemu.d/vm_name/hook_name/state_name.
# For a list of available hooks, please refer to https://www.libvirt.org/hooks.html
#

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"
MISC="''${@:4}"

BASEDIR="$(dirname $0)"

HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"

set -e # If a script exits with an error, we should as well.

# check if it's a non-empty executable file
if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
eval \"$HOOKPATH\" "$@"
elif [ -d "$HOOKPATH" ]; then
while read file; do
		# check for null string
		if [ ! -z "$file" ]; then
			eval \"$file\" "$@"
		fi
done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
			'';
		};

		# Windows 11 VM Starts here
		"libvirt/hooks/qemu.d/win11/vm-vars.conf" = {
			mode = "0775";
			text = ''
## Win11 VM Script Parameters

# To modify GNOME settings to disable the screensaver, we 
# need to specify the username and ID. As well, when the 
# VM is turned off, we need to restore the amount of idle 
# time until the screen is turned off (in seconds)
LOGGED_IN_USERNAME=quil
LOGGED_IN_USERID=1000

# How much memory we've assigned to the VM, in kibibytes 
VM_MEMORY=16000

# Set the governor to use when the VM is on, and which 
# one we should return to once the VM is shut down
VM_ON_GOVERNOR=performance
VM_OFF_GOVERNOR=schedutil

# Set the powerprofiles ctl profile to performance when 
# the VM is on, and power-saver when the VM is shut down
VM_ON_PWRPROFILE=performance
VM_OFF_PWRPROFILE=power-saver

# Set which CPU's to isolate, and your system's total
# CPU's. For example, an 8-core, 16-thread processor has 
# 16 CPU's to the system, numbered 0-15. For a 6-core,
# 12-thread processor, 0-11. The SYS_TOTAL_CPUS variable 
# should always reflect this.
#
# You can define these as a range, a list, or both. I've 
# included some examples:
#
# EXAMPLE=0-3,8-11
# EXAMPLE=0,4,8,12
# EXAMPLE=0-3,8,11,12-15
VM_ISOLATED_CPUS=0-1
SYS_TOTAL_CPUS=0-15
			'';
		};

		"libvirt/hooks/qemu.d/win11/prepare/begin/10-asusd-vfio.sh" = {
			mode = "0775";
			text = ''
#!/usr/bin/env bash

## Load VM variables
source "/etc/libvirt/hooks/qemu.d/win11/vm-vars.conf"

## Use supergfxctl to set graphics mode to vfio
echo "Setting graphics mode to VFIO..."
supergfxctl -m vfio

echo "Graphics mode set!"
sleep 1
			'';
		};

		"libvirt/hooks/qemu.d/win11/release/end/40-asusd-integrated.sh" = {
			mode = "0775";
			text = ''
#!/usr/bin/env bash

## Load VM variables
source "/etc/libvirt/hooks/qemu.d/win11/vm-vars.conf"

## Use supergfxctl to set graphics mode to vfio
echo "Resetting graphics mode back to integrated..."
supergfxctl -m integrated

echo "Graphics mode reset!"
sleep 1
			'';
		};
	};

	system.activationScripts.copyBin = {
		# The script will depend on your binary file
		deps = [ ];

		# The script content to run during activation
		text = ''
			# The full path to your binary in the Nix store
			sourceFile="${./virtualisation/acpitable.bin}"

			targetDir="/var/lib/libvirt/images"
			targetFile="$targetDir/acpitable.bin"

			# Create the directory and copy the file
			mkdir -p "$targetDir"
			cp "$sourceFile" "$targetFile"
			chmod 755 "$targetFile"
		'';
	};
}

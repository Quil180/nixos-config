{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.virtualisation = 
{ pkgs, username, ... }: 
{
	programs.dconf.enable = true;
	
  users.users.${username}.extraGroups = [
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
    pkgs.virtio-win
    pkgs.win-spice
		# Icon pack for buttons
		pkgs.adwaita-icon-theme
		(pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
			qemu-system-x86_64 \
				-bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
				"$@"
		'')
  ];

	# KVM/virtio stays: libvirt + virt-manager are still enabled (NixOS guest).
	boot = {
		kernelModules = [ "kvm-amd" ];
		extraModprobeConfig = "options kvm_amd ignore_msrs=1";
	};

}
;
}

{ pkgs, ... }: 
{

	programs.dconf.enable = true;
	
  users.users.quil.extraGroups = [ "libvirtd" ];

  services.spice-vdagentd.enable = true;

  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
				# For Windows VMs
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
        swtpm.enable = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
		# Virtual-Manager GUI
    virt-manager
    virt-viewer
		# SPICE client for visualizations
    spice
    spice-gtk
    spice-protocol
		# Drivers for Windows VM
    win-virtio
    win-spice
		# Icon pack for buttons
		adwaita-icon-theme
  ];
}

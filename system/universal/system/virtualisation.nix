_: {
  flake.nixosModules.virtualisation =
    {
      pkgs,
      config,
      username,
      ...
    }:
    {
      # VM definitions, networks and storage pools.
      persist.directories = [ "/var/lib/libvirt" ];

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
            # runAsRoot = true only stops the module emitting its own
            # `user = "qemu-libvirtd"` block into qemu.conf (libvirt's config
            # parser is first-match-wins for duplicate keys, so an earlier
            # qemu-libvirtd line would silently shadow `user = "quil"` below).
            # qemu still drops privileges — to the desktop user instead of
            # qemu-libvirtd, who cannot traverse /home/quil (mode 700). That
            # way guest media under the home dir (ISOs, disk images) works
            # without copying anything to /var/lib/libvirt.
            runAsRoot = true;
            verbatimConfig = ''
              namespaces = []
              user = "${username}"
              group = "users"
            '';
            swtpm.enable = true;
          };
        };
      };

      # qemu.conf only takes effect when libvirtd (re)starts; without this,
      # `nixos-rebuild switch` deploys a new config file but leaves a stale
      # daemon running (libvirtd.service itself rarely changes), which has
      # repeatedly caused confusing "Permission denied" failures.
      systemd.services.libvirtd.restartTriggers = [
        config.virtualisation.libvirtd.qemu.verbatimConfig
      ];

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

    };
}

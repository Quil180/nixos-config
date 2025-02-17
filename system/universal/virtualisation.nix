{
  pkgs,
  lib,
  ...
}: let
  gpuID = [
    # "1002:73ef" # gpu
    # "1002:ab28" # audio
  ];
in {
  boot = {
    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      ("vfio-pci.ids=" + lib.concatStringsSep "," gpuID)
    ];
    kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      "kvm-amd"
    ];
  };

  users.users.quil = {
    extraGroups = ["libvirtd"];
  };

  hardware.graphics.enable = true;
  programs.virt-manager.enable = true;
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            })
            .fd
          ];
        };
        swtpm.enable = true;
        runAsRoot = true;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
  };

  environment.sessionVariables.LIBVIRT_DEFAULT_URI = ["qemu:///session"];
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
  ];
}

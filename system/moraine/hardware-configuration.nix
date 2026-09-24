_: {
  # NOTE: hand-written, deliberately NOT the output of `nixos-generate-config`.
  # moraine does not exist yet, so this is a placeholder declaring only what
  # the platform and the disko layout require. On the real machine, run
  #   sudo nixos-generate-config --show-hardware-config
  # and diff the result into this file (initrd modules, CPU, hostPlatform).
  flake.nixosModules.moraine_hardware =
    {
      config,
      lib,
      ...
    }:
    {
      # Uncomment if any hardware is not auto-detected:
      # imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "uas"
        "usb_storage"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ "dm-snapshot" ]; # LUKS -> LVM -> btrfs (disko.nix)
      boot.kernelModules = [ "kvm-amd" ]; # Ryzen 7 7800X3D (SVM)
      boot.extraModulePackages = [ ];

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}

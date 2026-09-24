{ topConfig, ... }:
{
  flake.nixosModules.proxmox_vm =
    { modulesPath, lib, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        topConfig.flake.nixosModules.simple_disko
      ];

      boot.initrd.availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [
        "kvm-intel"
        "kvm-amd"
      ];
      boot.extraModulePackages = [ ];

      # For virtual machines, we usually use the default virtio network.
      # mkDefault so a VM can pin a static address without a conflicting-definition
      # error (same trap as useRoutingFeatures had in vpns/tailscale.nix).
      networking.useDHCP = lib.mkDefault true;
    };
}

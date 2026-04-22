{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.proxmox_vm = 
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") topConfig.flake.nixosModules.simple_disko ];

  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # For virtual machines, we usually use the default virtio network
  networking.useDHCP = true;
}
;
}

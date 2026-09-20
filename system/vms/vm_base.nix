{ topConfig, lib, pkgs, ... }:
{
  # Shared base for the Proxmox VMs: crust, baguette, scone, croissant,
  # biscotti, biscuit. Per-host specifics stay in system/vms/<host>/.
  flake.nixosModules.vm_base =
    { lib, ... }:
    {
      imports = [
        topConfig.flake.nixosModules.proxmox_vm # qemu-guest profile + simple_disko + virtio
        topConfig.flake.nixosModules.security
        topConfig.flake.nixosModules.monitoring # node exporter + journal shipping to Loki
      ];

      # server_notes note 1: memory ballooning needs the guest agent inside.
      # NOTE: the option is services.qemuGuest (it used to be qemuGuestAgent).
      services.qemuGuest.enable = true;

      # Proxmox VMs boot UEFI and simple_disko lays down an ESP at /boot.
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
}

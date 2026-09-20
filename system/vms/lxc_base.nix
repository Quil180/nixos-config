{ topConfig, lib, pkgs, ... }:
{
  # Shared base for the NixOS LXCs: crepe, bagel, muffin, toast, macaron.
  #
  # A Proxmox LXC shares the host kernel: NO disko, NO bootloader, NO kernel
  # modules. `boot.isContainer = true` is what tells NixOS that — without it
  # the toplevel eval fails with "You must set ... to make the system
  # bootable" (verified). GPU access for toast comes from a /dev/dri
  # bind-mount plus cgroup device lines in the Proxmox container .conf,
  # not from vfio (server_notes note 4).
  flake.nixosModules.lxc_base =
    { lib, ... }:
    {
      imports = [
        topConfig.flake.nixosModules.security
        topConfig.flake.nixosModules.monitoring
      ];

      boot.isContainer = true;

      networking.useDHCP = lib.mkDefault true;
    };
}

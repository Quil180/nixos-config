{ pkgs, username, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "biscotti";

  nix.settings.trusted-users = [
    "root"
    username
  ];

  # build farm resources
  nix.settings.max-jobs = 12; # from server_notes 12 vCPU
}

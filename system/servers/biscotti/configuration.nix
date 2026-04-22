{ topConfig, lib, pkgs, ... }:
{
  configurations.nixos.biscotti.module = 
{ pkgs, username, ... }:
{
  imports = [ topConfig.flake.nixosModules.server_base topConfig.flake.nixosModules.proxmox_vm ];

  networking.hostName = "biscotti";

  nix.settings.trusted-users = [
    "root"
    username
  ];

  # build farm resources
  nix.settings.max-jobs = 12; # from server_notes 12 vCPU
}
;
}

{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.simple_disko = 
{ ... }: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda"; # Usually sda in Proxmox VMs
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
;
}

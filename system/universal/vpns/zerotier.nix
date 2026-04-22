{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.zerotier = 
{...}: {
  services.zerotierone = {
    enable = true;
    joinNetworks = ["565799d8f611794d"];
  };
}
;
}

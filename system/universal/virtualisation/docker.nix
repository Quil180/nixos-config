{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.docker = 
{pkgs, username, ...}: {
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
  users.users.${username} = {
    extraGroups = [ "docker" ];
  };
	virtualisation.docker.enable = true;
}
;
}

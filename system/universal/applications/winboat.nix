{ pkgs, username, ... }:
{
  users.users.${username}.extraGroups = [ "docker" ];
  virtualisation.docker.enable = true;
  
  environment.systemPackages = [
    (pkgs.winboat.overrideAttrs (oldAttrs: {
      # Fixes "npm failed to install dependencies" errors
      makeCacheWritable = true; 
      npmFlags = (oldAttrs.npmFlags or []) ++ [ "--legacy-peer-deps" ];
    }))
  ];
}

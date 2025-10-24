{pkgs, username, ...}:
{

  users.users.${username}.extraGroups = [ "docker" ];
  virtualisation.docker.enable = true;
  environment.systemPackages = [
    pkgs.winboat
  ];
}

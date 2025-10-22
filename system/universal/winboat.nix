{inputs, username, ...}:
{
  imports = [
    inputs.winboat.nixosModules.default
  ];

  users.users.${username}.extraGroups = [ "docker" ];
  services.winboat.enable = true;
}

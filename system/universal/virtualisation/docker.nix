_: {
  flake.nixosModules.docker = { pkgs, username, ... }: {
    # Images, containers and volumes.
    persist.directories = [ "/var/lib/docker" ];

    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];
    users.users.${username} = {
      extraGroups = [ "docker" ];
    };
    virtualisation.docker.enable = true;
  };
}

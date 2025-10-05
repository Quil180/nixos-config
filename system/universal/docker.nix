{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    docker
    docker-compose
  ];
  users.users.quil = {
    extraGroups = ["docker"];
  };
	virtualisation.docker.enable = true;
}

{ topConfig, lib, pkgs, ... }:
{
  configurations.nixos.scone.module = 
{ pkgs, ... }:
{
  imports = [ topConfig.flake.nixosModules.server_base topConfig.flake.nixosModules.proxmox_vm ];

  networking.hostName = "scone";

  age.secrets.gitea_admin_pass.file = ../../../secrets/gitea_admin_pass.age;

  services.gitea = {
    enable = true;
    # basic config
    settings.server.DOMAIN = "gitea.local";
    # adminPasswordFile = config.age.secrets.gitea_admin_pass.path; # Example usage
  };

  services.homepage-dashboard = {
    enable = true;
    # Homepage config (services, bookmarks, etc.)
  };

  # NAS Mount
  fileSystems."/mnt/git_lfs" = {
    device = "breadbox:/mnt/git_lfs";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    3000
    8080
  ]; # Gitea and Homepage
}
;
}

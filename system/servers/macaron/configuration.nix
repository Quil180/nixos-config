{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
    ../../universal/virtualisation/docker.nix
  ];

  networking.hostName = "macaron";

  services.vaultwarden = {
    enable = true;
    # Vaultwarden config
  };

  age.secrets.macaron_pg_pass.file = ../../../secrets/macaron_pg_pass.age;
  age.secrets.macaron_authentik_secret.file = ../../../secrets/macaron_authentik_secret.age;

  # Authentik via Docker (since NixOS module is not in nixpkgs)
  # docker-compose.yml is provided in the same directory.
  # Use agenix paths in environment for docker-compose if needed, 
  # but here we just declare them.

  networking.firewall.allowedTCPPorts = [
    80
    443
    8222
  ];
}

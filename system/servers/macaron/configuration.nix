{ pkgs, ... }:
{
  imports = [
    ../../universal/system/server_base.nix
    ../../universal/system/proxmox_vm.nix
  ];

  networking.hostName = "macaron";

  services.vaultwarden = {
    enable = true;
    # Vaultwarden config
  };

  # services.authentik = {
  #   enable = true;
  #   # Authentik config
  # };

  networking.firewall.allowedTCPPorts = [ 80 443 8222 ]; # Authentik and Vaultwarden
}

{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.tailscale =
    { lib, ... }:
    {
      services.tailscale = {
        enable = true;
        # mkDefault so a host can dial routing features back without hitting a
        # conflicting-definition error, e.g. a plain client VM:
        #   services.tailscale.useRoutingFeatures = "client";
        # Upstream default is "none"; "both" enables the subnet-router/exit-node
        # sysctls and the loose reverse-path firewall setting.
        useRoutingFeatures = lib.mkDefault "both";
      };

      # No environment.systemPackages entry here: enabling the service already
      # puts cfg.package (pkgs.tailscale) on the PATH — see
      # nixos/modules/services/networking/tailscale.nix.
    };
}

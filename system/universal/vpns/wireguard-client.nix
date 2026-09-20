{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  # Turns a personal host into a WireGuard client of the homelab. Everything
  # that differs per host comes from the mesh in homelab-net.nix, so a host
  # needs no WireGuard config of its own and no manual setup.
  flake.nixosModules.wireguard_client =
    { config, hostname, ... }:
    let
      inherit (config.homelab.net)
        crustEndpoint crustWgPublicKey wgSubnet lanSubnet wgClients;
      me = wgClients.${hostname};

      # crust does not exist yet, so crustEndpoint is still the RFC 2606
      # sentinel. wg-quick resolves the endpoint before adding the peer, so
      # autostarting now fails the unit on every switch and boot. Declare the
      # interface but leave it dormant; setting a real endpoint lights it up
      # on both hosts with no other edit.
      endpointProvisioned = crustEndpoint != "change-me.invalid:51820";
    in
    {
      imports = [ topConfig.flake.nixosModules.homelab_net ];

      networking.wg-quick.interfaces.wg0 = {
        autostart = endpointProvisioned;
        address = [ "${me.address}/24" ];
        # Resolve the internal domain through crust's dnsmasq — without a
        # hostname, Caddy cannot pick a vhost, so this is what makes the
        # service URLs work from off-LAN.
        dns = [ "10.10.0.1" ];
        privateKeyFile = config.age.secrets.wg_client.path;

        peers = [
          {
            publicKey = crustWgPublicKey;
            endpoint = crustEndpoint;
            # Split tunnel: only the tunnel subnet and the homelab LAN go
            # through crust. Ordinary internet traffic uses the local link.
            allowedIPs = [ wgSubnet lanSubnet ];
            # This side is behind NAT, so it has to keep the tunnel open.
            persistentKeepalive = 25;
          }
        ];
      };

      # wg-quick owns this interface; keep NetworkManager's hands off it or it
      # can be torn down from under the tunnel.
      networking.networkmanager.unmanaged = [ "wg0" ];

      # wg-quick hands its `dns` entries to resolvconf, so resolvconf must be
      # the thing that owns resolv.conf. NetworkManager then follows
      # automatically: its module derives rc-manager=resolvconf from this very
      # option (networkmanager.nix:24), so setting `dns` here is unnecessary —
      # and "resolvconf" is not even a valid value for it.
      networking.resolvconf.enable = lib.mkDefault true;

      age.secrets.wg_client.file = me.secretFile;
    };
}

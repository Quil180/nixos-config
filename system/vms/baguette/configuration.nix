{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.baguette.module =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [ vm_base lan_access ];

      networking.hostName = "baguette";
      system.stateVersion = "26.11";

      # ---- RustDesk server (hbbs + hbbr), for remote access into the network.
      services.rustdesk-server = {
        enable = true;
        # Not openFirewall: that would expose these to the whole LAN *and*, via
        # the public IPv6 prefix, to the internet. Scoped below instead.
        openFirewall = false;
        # TODO(quil): relayHosts should name this box as clients see it, e.g.
        #   relayHosts = [ "baguette.<domain>" ];  # must match the RustDesk
        #   client's configured relay, or clients fall back to the public relay.
      };

      # RustDesk is reachable from WireGuard clients only, matching the
      # "WireGuard gates access" model in server_notes note 3. If you ever want
      # to reach it from a machine that is NOT on the VPN, this is the rule to
      # change — but then it is public, so weigh that carefully.
      services.lanAccess = {
        fromWireguard = [ 21115 21116 21117 21118 21119 ];
        fromWireguardUdp = [ 21116 ];
      };
    };

  configurations.nixos.baguette.tags = [ "vm" "server" "remote-access" ];
}

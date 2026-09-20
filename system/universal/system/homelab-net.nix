{ topConfig, lib, pkgs, ... }:
{
  # ---- THE single source of truth for the homelab network -----------------
  # Everything that needs crust's address, the internal domain or a subnet
  # reads these options instead of hardcoding them. Change a value HERE and
  # every consumer follows: firewall rules, Caddy's vhosts, crust's own
  # address. Nothing else should contain these literals.
  flake.nixosModules.homelab_net =
    { lib, ... }:
    {
      options.homelab.net = {
        domain = lib.mkOption {
          type = lib.types.str;
          default = "yousef.wiki";
          description = "The domain every service is served under (Caddy vhosts are derived from it).";
        };

        crustAddress = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.5";
          description = ''
            crust's LAN address: the only source allowed to reach the service
            UIs, and the address Caddy serves the internal domain from.

            TODO(quil): PROVISIONAL home-LAN placeholder — pin crust to match
            (DHCP reservation on Pretzel, or the static profile below) and keep
            this the single value in sync.
          '';
        };

        lanPrefixLength = lib.mkOption {
          type = lib.types.int;
          default = 24;
          description = "Prefix length for crustAddress.";
        };

        lanSubnet = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.0/24";
          description = "The LAN every host sits on.";
        };

        lanGateway = lib.mkOption {
          type = lib.types.str;
          default = "192.168.5.1";
          description = "The LAN gateway / DNS (Pretzel, pfSense).";
        };

        crustEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "change-me.invalid:51820";
          description = ''
            Where WireGuard clients dial crust: `<host or IP>:<port>`.

            TODO(quil): PROVISIONAL. crust does not exist until December, so
            neither its public IP nor a DDNS name is knowable yet. `.invalid`
            is reserved by RFC 2606 and can never resolve, so a client that
            has not been updated fails loudly instead of silently dialling
            nothing. Set this once, and both personal hosts follow.
          '';
        };

        crustWgPublicKey = lib.mkOption {
          type = lib.types.str;
          default = "gCheAbKaTBpf9mTayOSGuj+WvmhPLnRT9Ysan9Xe6QI=";
          description = "crust's WireGuard public key (the private half is in secrets/wg_crust.age).";
        };

        wgClients = lib.mkOption {
          default = {
            snowflake = {
              address = "10.10.0.2";
              publicKey = "YE7tosefR5t0ojrqBX+C6fl4020ViECXfbH0KrRvi24=";
              secretFile = ../../../secrets/wg_snowflake.age;
            };
            moraine = {
              address = "10.10.0.3";
              publicKey = "gBVIBT0F9Y9UKE/A+fe8UHq7rqzJxtWbLJXTC6i3QC8=";
              secretFile = ../../../secrets/wg_moraine.age;
            };
          };
          description = ''
            The WireGuard mesh: one entry per client. Both sides read from
            here, so a client's tunnel address and crust's peer entry for it
            can never drift apart. Public keys are not secret; the private
            halves are agenix secrets named by `secretFile`.
          '';
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              address = lib.mkOption { type = lib.types.str; description = "Tunnel address (no prefix)."; };
              publicKey = lib.mkOption { type = lib.types.str; description = "Client public key."; };
              secretFile = lib.mkOption { type = lib.types.path; description = "Encrypted private key."; };
            };
          });
        };

        wgSubnet = lib.mkOption {
          type = lib.types.str;
          default = "10.10.0.0/24";
          description = "The WireGuard client subnet — the only path in from outside.";
        };
      };
    };
}

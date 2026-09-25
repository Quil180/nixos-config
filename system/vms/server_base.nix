{ topConfig, ... }:
{
  # What every homelab server (Proxmox VM or LXC) shares, whatever its role:
  # a login, SSH, hardening, monitoring and the scoped firewall. Imported by
  # vm_base and lxc_base, so hosts never import this directly.
  flake.nixosModules.server_base =
    { username, ... }:
    {
      imports = with topConfig.flake.nixosModules; [
        security
        monitoring # node exporter + journal shipping to Loki
        lan_access # services.lanAccess.* + homelab.expose
      ];

      # The one login on every server. Key-only (security.nix disables
      # passwords), and no password is set: the agenix password secret is
      # sealed to the user key only, which servers never hold.
      users.users.${username} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = [
          (builtins.readFile ../keys/id_snowflake.pub)
        ];
      };

      # With no password, sudo authenticates against the forwarded SSH agent
      # instead (`ssh -A`, or `nixos-rebuild --target-host … --sudo` from a
      # shell whose agent holds the key). The key it accepts is the same one
      # authorised for login above.
      security.pam.sshAgentAuth.enable = true;
      security.pam.services.sudo.sshAgentAuth = true;

      services.openssh = {
        enable = true;
        # Not openFirewall: that opens 22 on IPv6 too, i.e. to the internet
        # over the public prefix. IPv4 LAN + NetBird only, like everything
        # else here.
        openFirewall = false;
      };
      services.lanAccess = {
        fromLan = [ 22 ];
        fromVpn = [ 22 ];
      };
    };
}

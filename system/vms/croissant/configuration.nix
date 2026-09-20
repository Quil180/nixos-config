{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  configurations.nixos.croissant.module =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      # Users whose traffic must never leave un-tunnelled. The whole stack is
      # listed by default, so indexer/tracker calls originate from the VPN IP.
      #
      # NOTE: every entry must be a REAL account. iptables resolves the name
      # via NSS when the rule is inserted, and the firewall script runs under
      # `sh -e` — an unknown name aborts the entire firewall script, leaving a
      # half-applied ruleset. That is why prowlarr gets a static account below.
      killswitchUsers = [ "qbittorrent" "sonarr" "radarr" "prowlarr" "bazarr" ];

      # crust's LAN address — the ONLY source allowed to reach the service UIs
      # below. TODO(quil): PROVISIONAL placeholder for a home LAN
      # (192.168.5.0/24) and WILL CHANGE. Set it to crust's real, *pinned*
      # address, and pin crust with a DHCP reservation on Pretzel (pfSense)
      # rather than a static NixOS address, so its interface name never has to
      # be guessed. If this value is wrong Caddy gets 502s; if crust's lease
      # moves, the rules silently stop matching anything.
      crustAddress = "192.168.5.5";

      killswitchRules = lib.concatMapStrings (u: ''
        ip46tables -A vpn-killswitch -m owner --uid-owner ${u} -o lo -j ACCEPT
        ip46tables -A vpn-killswitch -m owner --uid-owner ${u} -o tun0 -j ACCEPT
        ip46tables -A vpn-killswitch -m owner --uid-owner ${u} -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ip46tables -A vpn-killswitch -m owner --uid-owner ${u} -j REJECT
      '') killswitchUsers;
    in
    {
      imports = with topConfig.flake.nixosModules; [ vm_base lan_access ];

      networking.hostName = "croissant";
      system.stateVersion = "26.11";

      # ---- ExpressVPN via OpenVPN (ExpressVPN ships .ovpn profiles).
      #      Native client, no Docker — qBittorrent is bound to the tun device
      #      and the firewall blocks it from leaking over the default route.
      #
      #      Both the profile and the credentials are agenix secrets: the .ovpn
      #      embeds a client cert/key + tls-auth, and the module's
      #      authUserPass option takes the username in *plain text*, so it is
      #      deliberately NOT used here.
      services.openvpn.servers.expressvpn = {
        autoStart = true;
        updateResolvConf = true;
        config = ''
          config ${config.age.secrets.expressvpn_ovpn.path}
          # The profile ships a bare `auth-user-pass` (interactive prompt).
          # This later directive overrides it with a two-line
          # username/password file so both stay out of the repo.
          auth-user-pass ${config.age.secrets.expressvpn_auth.path}
        '';
      };

      age = {
        # Servers decrypt with their own SSH host key — the user's private key
        # never lands on them (the serverKeys model).
        identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        secrets = {
          expressvpn_ovpn.file = ../../../secrets/expressvpn_ovpn.age;
          expressvpn_auth.file = ../../../secrets/expressvpn_auth.age;
        };
      };

      # ---- Exit-node rotation.
      #      remote-random (inside the profile) shuffles the 7 endpoints at
      #      startup, and OpenVPN fails over to the next one if the chosen
      #      endpoint dies — but it has no *time-based* rotation. Restarting
      #      the unit is what re-rolls the exit IP. RandomizedDelaySec keeps
      #      the pattern from being clock-regular.
      systemd.services.expressvpn-rotate = {
        description = "Re-roll the ExpressVPN exit node";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart openvpn-expressvpn.service";
        };
      };

      systemd.timers.expressvpn-rotate = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*-*-* 00/4:00:00"; # every 4 hours
          Persistent = true;
          RandomizedDelaySec = "20m";
        };
      };

      # ---- qBittorrent, bound to the VPN interface (killswitch).
      services.qbittorrent = {
        enable = true;
        openFirewall = false;
        webuiPort = 8080;
        serverConfig.BitTorrent = {
          # TODO(quil): verify these keys bind qBittorrent to the tun device so
          # traffic can never leave via the LAN/default route.
          Interface = "tun0";
          InterfaceName = "tun0";
        };
      };

      # ---- Killswitch -------------------------------------------------------
      # qBittorrent may only reach the internet through the VPN tunnel; if the
      # tunnel is down its packets are REJECTed rather than escaping over the
      # default route. This matters more now that the exit re-rolls every 4h.
      #
      # The NixOS iptables firewall only owns INPUT/FORWARD, so OUTPUT is ours.
      # A dedicated chain stops repeated firewall reloads from stacking
      # duplicate rules: the chain is flushed and rebuilt every time, while the
      # jump from OUTPUT into it is added only once. `ip46tables` is defined in
      # the firewall's own extraCommands, so this covers IPv6 too (enableIPv6
      # is on) — without it, IPv6 would be a silent bypass.
      #
      # DNS rides the tunnel: updateResolvConf = true pushes ExpressVPN's
      # resolvers in via resolvconf while connected. When the tunnel drops,
      # resolvconf removes them, DNS falls back to the LAN resolver, and that
      # is REJECTed too — i.e. it fails closed. If DNS ever proves flaky in
      # practice, the escape hatch is to add a LAN-resolver ACCEPT before the
      # final REJECT, at the cost of leaking lookups.
      networking.firewall.extraCommands = ''
        ip46tables -N vpn-killswitch 2>/dev/null || true
        ip46tables -F vpn-killswitch
        ${killswitchRules}    # hook into OUTPUT exactly once
        ip46tables -C OUTPUT -j vpn-killswitch 2>/dev/null || \
          ip46tables -A OUTPUT -j vpn-killswitch

      '';

      # ---- *arr stack.
      services.prowlarr.enable = true;
      services.sonarr.enable = true;
      services.radarr.enable = true;
      services.bazarr.enable = true;

      # Prowlarr ships with systemd `DynamicUser = true`: it has no static
      # account and its uid is allocated at every start, so it can never be
      # matched by --uid-owner. Give it a real account so the killswitch can
      # cover it like the rest of the stack.
      users.groups.prowlarr = { };
      users.users.prowlarr = {
        isSystemUser = true;
        group = "prowlarr";
      };

      systemd.services.prowlarr.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "prowlarr";
        Group = "prowlarr";
      };

      # ---- Service UIs: reachable ONLY from crust ---------------------------
      # crust's Caddy terminates TLS and reverse-proxies to these ports, so the
      # *arr / qBittorrent UIs are never exposed directly — the only way in is
      # through the WireGuard VPN and then Caddy.
      #
      # Explicit IPv4 rules rather than allowedTCPPorts, because that option
      # opens a port for BOTH address families — and this LAN advertises a
      # *public* IPv6 prefix (2605:a601:1525:fa01::/64), so opening these on v6
      # would publish them to the internet. There is deliberately no ip6tables
      # counterpart, so the ports stay closed on IPv6.
      #
      # Stock servarr/qBittorrent listen ports. Change one in an app's UI and
      # you must change it here too, or Caddy will 502.
      #
      # The rules themselves come from the shared lan_access module below —
      # extraCommands can only be assigned once per module *file*, but separate
      # modules merge (it is types.lines), so the killswitch block above and
      # these rules coexist.
      services.lanAccess.fromCrust = [ 8080 8989 7878 9696 6767 ];

      # ---- /mnt/media from Breadbox (TrueNAS).
      fileSystems."/mnt/media" = {
        # TODO(quil): confirm the exact export path on Breadbox.
        device = "breadbox:/mnt/media";
        fsType = "nfs";
        options = [ "_netdev" "x-systemd.automount" "noauto" "nofail" ];
      };
    };

  configurations.nixos.croissant.tags = [ "vm" "server" "media-acquisition" ];
}

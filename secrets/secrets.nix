let
  # User keys: used by you to encrypt/edit secrets (and, on the personal
  # machines, to decrypt them — see age.identityPaths in `workstation`).
  user_quil = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5X4Lyn55CjuIkzMwUqtcmak68QGzL0obzLME7ICvvp quil@snowflake";
  users = [ user_quil ];

  # Server host keys: each server decrypts its own secrets with
  # /etc/ssh/ssh_host_ed25519_key (the serverKeys model — the user's private
  # key never lands on a server). `null` = the host is not installed yet, so
  # its secrets are sealed to the user key only and WILL NOT decrypt there.
  #
  # Once a host exists: paste `cat /etc/ssh/ssh_host_ed25519_key.pub` from it
  # below, then rekey from the secrets/ directory:
  #   nix run github:ryantm/agenix -- -r -i ~/.ssh/id_ed25519
  hosts = {
    crust = null; # caddy_porkbun_env, netbird_crust_setup_key
    bagel = null; # netbird_bagel_setup_key
    croissant = null; # expressvpn_ovpn, expressvpn_auth
    biscuit = null; # paperless_admin
    muffin = null; # grafana_secret_key
    macaron = null; # vaultwarden_env
  };

  # The user key plus the host's key, once it has one.
  serverKeys = host: users ++ (if hosts.${host} == null then [ ] else [ hosts.${host} ]);
in
{
  "quil_password.age".publicKeys = users; # Common user password
  "root_password.age".publicKeys = users;
  "git_identity.age".publicKeys = users;
  "snowflake.age".publicKeys = users;

  # Caddy's Porkbun API credentials for the ACME DNS-01 challenge, plus the
  # ACME contact address (kept here so the real mailbox is not in the repo).
  # Values are real as of now — re-encrypt this file if you rotate the API keys.
  "caddy_porkbun_env.age".publicKeys = serverKeys "crust";
  # NetBird setup key for crust's unattended enrolment: create a reusable key
  # in the NetBird dashboard, then from this directory:
  #   nix run github:ryantm/agenix -- -e netbird_crust_setup_key.age
  # crust skips auto-login until this file exists.
  "netbird_crust_setup_key.age".publicKeys = serverKeys "crust";
  # Same for bagel, the backup routing peer: a one-off key with the `routers`
  # auto-group (server_notes "NetBird: Bagel as backup routing peer").
  #   nix run github:ryantm/agenix -- -e netbird_bagel_setup_key.age
  "netbird_bagel_setup_key.age".publicKeys = serverKeys "bagel";

  # ExpressVPN. Both the .ovpn (it embeds a client cert+key and tls-auth) and
  # the username/password live here so nothing lands in the public repo.
  "expressvpn_ovpn.age".publicKeys = serverKeys "croissant";
  "expressvpn_auth.age".publicKeys = serverKeys "croissant";

  "paperless_admin.age".publicKeys = serverKeys "biscuit";
  "grafana_secret_key.age".publicKeys = serverKeys "muffin";
  "vaultwarden_env.age".publicKeys = serverKeys "macaron";
}

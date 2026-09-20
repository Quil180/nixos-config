let
  # Host keys: Used by the system to decrypt secrets at boot.
  # Replace these with the actual host keys once the systems are installed.
  # You can find the host key on the target machine in /etc/ssh/ssh_host_ed25519_key.pub
  snowflake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGnAyGD5Ah3rhIxOJi39w5Ac0duyOM2nyWNHQocsokA root@snowflake";
  # User keys: Used by you to encrypt/edit secrets.
  user_quil = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL5X4Lyn55CjuIkzMwUqtcmak68QGzL0obzLME7ICvvp quil@snowflake";

  # Grouping keys
  systems = [
    snowflake
  ];
  users = [ user_quil ];
  allKeys = users;

  # For specific servers
  serverKeys = nodeKey: [
    nodeKey
    user_quil
  ];

in
{
  "quil_password.age".publicKeys = allKeys; # Common user password
  "root_password.age".publicKeys = allKeys;
  "git_identity.age".publicKeys = allKeys;
  "snowflake.age".publicKeys = allKeys;

  # ExpressVPN. Both the .ovpn (it embeds a client cert+key and tls-auth) and
  # the username/password live here so nothing lands in the public repo.
  # TODO(quil): switch these to `serverKeys croissant` once croissant's SSH
  # host key exists, then rekey:
  #   nix run github:ryantm/agenix -- -r -i ~/.ssh/id_ed25519
  # Server-side secrets. All still sealed to the user key, so each host needs
  # `serverKeys <host>` + a rekey once its SSH host key exists (December):
  # paperless (biscuit), grafana (muffin), vaultwarden (macaron).
  # Caddy's Porkbun API credentials for the ACME DNS-01 challenge, plus the
  # ACME contact address (kept here so the real mailbox is not in the repo).
  # Values are real as of now — re-encrypt this file if you rotate the API keys.
  "caddy_porkbun_env.age".publicKeys = allKeys;

  "paperless_admin.age".publicKeys = allKeys;
  # WireGuard private keys, pre-generated so the clients need no setup. The
  # public halves are not secret and live in homelab-net.nix.
  "wg_crust.age".publicKeys = allKeys;
  "wg_snowflake.age".publicKeys = allKeys;
  "wg_moraine.age".publicKeys = allKeys;

  "grafana_secret_key.age".publicKeys = allKeys;
  "vaultwarden_env.age".publicKeys = allKeys;

  "expressvpn_ovpn.age".publicKeys = allKeys;
  "expressvpn_auth.age".publicKeys = allKeys;
}

let
  # Host keys: Used by the system to decrypt secrets at boot.
  # Replace these with the actual host keys once the systems are installed.
  # You can find the host key on the target machine in /etc/ssh/ssh_host_ed25519_key.pub
  snowflake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfBViNTsKy2t26QrSelb7cvrsfwErbrATPfcPacjtdx root@snowflake";
  crust = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_crust_host_key root@crust";
  baguette = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_baguette_host_key root@baguette";
  scone = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_scone_host_key root@scone";
  pancake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_pancake_host_key root@pancake";
  croissant = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_croissant_host_key root@croissant";
  biscotti = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_biscotti_host_key root@biscotti";
  macaron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_macaron_host_key root@macaron";
  muffin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAPlaceholder_muffin_host_key root@muffin";

  # User keys: Used by you to encrypt/edit secrets.
  user_quil = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINIHmKLah2TNwOeg1CiM2uXd0c0ICrpymUa1Q0A7zSdg quil@snowflake";

  # Grouping keys
  systems = [
    snowflake
    crust
    baguette
    scone
    pancake
    croissant
    biscotti
    macaron
    muffin
  ];
  users = [ user_quil ];
  allKeys = systems ++ users;

  # For specific servers
  serverKeys = nodeKey: [
    nodeKey
    user_quil
  ];

in
{
  "snowflake.age".publicKeys = [
    snowflake
    user_quil
  ];
  "luks.age".publicKeys = [
    snowflake
    user_quil
  ];
  "quil_password.age".publicKeys = allKeys; # Common user password
  "github_token.age".publicKeys = allKeys;
  "git_identity.age".publicKeys = allKeys;

  # Server specific secrets
  "netbird_key.age".publicKeys = [
    crust
    user_quil
  ];
  "rustdesk_key.age".publicKeys = [
    baguette
    user_quil
  ];
  "gitea_admin_pass.age".publicKeys = [
    scone
    user_quil
  ];
  "vpn_wg_key.age".publicKeys = [
    croissant
    user_quil
  ];
  "macaron_pg_pass.age".publicKeys = [
    macaron
    user_quil
  ];
  "macaron_authentik_secret.age".publicKeys = [
    macaron
    user_quil
  ];
  "grafana_admin_pass.age".publicKeys = [
    muffin
    user_quil
  ];
}

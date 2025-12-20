let
  # Host keys: Used by the system to decrypt secrets at boot.
  snowflake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOfBViNTsKy2t26QrSelb7cvrsfwErbrATPfcPacjtdx root@snowflake";

  # User keys: Used by you to encrypt/edit secrets.
  user_quil = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINIHmKLah2TNwOeg1CiM2uXd0c0ICrpymUa1Q0A7zSdg quil@snowflake";

  # Grouping keys
  systems = [ snowflake ];
  users = [ user_quil ];
  allKeys = systems ++ users;

in
{
  "snowflake.age".publicKeys = allKeys;
  "luks.age".publicKeys = allKeys;
  "quil_password.age".publicKeys = allKeys;
  "github_token.age".publicKeys = allKeys;
  "git_identity.age".publicKeys = allKeys;
}

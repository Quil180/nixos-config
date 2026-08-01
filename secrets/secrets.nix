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
  allKeys = systems ++ users;

  # For specific servers
  serverKeys = nodeKey: [
    nodeKey
    user_quil
  ];

in
{
  "quil_password.age".publicKeys = allKeys; # Common user password
  "git_identity.age".publicKeys = allKeys;
  "snowflake.age".publicKeys = allKeys;
}

{ inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "/home/quil/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = false;

    secrets = {
      "private_keys/quil" = {
        path = "/home/quil/.ssh/id_private";
      };
    };
  };
}

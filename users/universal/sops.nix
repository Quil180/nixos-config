{ inputs, ... }:
let
  USER = "quil";
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    age.keyFile = "/home/${USER}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets.yaml;
    validateSopsFiles = false;

    secrets = {
      "private_keys/${USER}" = {
        path = "/home/${USER}/.ssh/id_ed25519";
      };
      "public_keys/${USER}" = {
        path = "/home/${USER}/.ssh/id_ed22519.pub";
      };
    };
  };
}

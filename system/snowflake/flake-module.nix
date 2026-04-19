{ inputs, ... }:

{
  flake.nixosConfigurations.snowflake = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      system = "x86_64-linux";
      username = "quil";
      dotfilesDir = "/home/quil/.dotfiles";
    };
    modules = [
      inputs.disko.nixosModules.default
      inputs.impermanence.nixosModules.impermanence
      inputs.agenix.nixosModules.default
      inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402

      ./disko.nix
      ./configuration.nix
    ];
  };
}

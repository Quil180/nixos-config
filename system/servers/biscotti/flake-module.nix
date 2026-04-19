{ inputs, ... }:

{
  flake.nixosConfigurations.biscotti = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      system = "x86_64-linux";
      username = "quil";
      dotfilesDir = "/home/quil/.dotfiles";
    };
    modules = [
      inputs.disko.nixosModules.default
      inputs.agenix.nixosModules.default
      
      ./configuration.nix
    ];
  };
}

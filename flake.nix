{
  description = "My personal flake for the setup on my G14 2022 laptop.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";

    };
    # stylix for auto-ricing
    stylix.url = "github:danth/stylix";
  };

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        nixos-quil = lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix # system config file
          ];
        };
      };
      homeConfigurations = {
        quil = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            ./home.nix
            # inputs.stylix.nixosModules.stylix
          ];
        };
      };

    };
}

{
  description = "My personal flake for the setup on my G14 2022 laptop.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";

    };
    # stylix for auto-ricing
    stylix = {
      url = "github:danth/stylix";
      inputs.base16.follows = "base16";
    };
    base16.url = "github:Noodlez1232/base16.nix/slugify-fix";
    # nixvim for neovim
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            inputs.stylix.nixosModules.stylix
          ];
        };
      };
      homeConfigurations = {
        quil = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home.nix
            inputs.nixvim.homeManagerModules.nixvim
            inputs.stylix.homeManagerModules.stylix
          ];
        };
      };

    };
}

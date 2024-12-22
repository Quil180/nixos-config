{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # disk declaration package
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # to clear out root folder on boot
    impermanence = {
      url = "github:nix-community/impermanence";
    };

    # dotfile declaration package
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # auto color ricing
    # stylix = {
    #   url = "github:danth/stylix";
    #   inputs.base16.follows = "base16";
    # };
    # base16.url = "github:Noodlez1232/base16.nix/slugify-fix"; # dependency for stylix

    # neovim declaration package
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # firefox declaration package
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vencord declaration package
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix for secretes management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: # to enable stylix, put it into outputs
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      nixosConfigurations = {
        snowflake = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            inputs.disko.nixosModules.default
            inputs.impermanence.nixosModules.impermanence
            # inputs.stylix.nixosModules.stylix

            users/quil/disko.nix
            users/quil/configuration.nix
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
            users/quil/home.nix
          ];
        };
      };
    };
}

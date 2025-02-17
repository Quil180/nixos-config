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

    # neovim declaration package
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # firefox addons declaration package
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vencord declaration package
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-colors for home-manager ricing
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nvf,
<<<<<<< HEAD
=======
    nixos-hardware,
>>>>>>> tmp
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> tmp
    neovimConfig = {
      imports = [
        packages/neovim/nvf-main.nix
      ];
    };
<<<<<<< HEAD

    customNeovim = nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [neovimConfig];
    };
  in {

    packages."x86_64-linux".default =
      (
        nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [packages/neovim/nvf-main.nix];
        }
      )
      .neovim;
=======
      neovimConfig = {
        imports = [
          packages/neovim/nvf-main.nix
        ];
      };

      customNeovim = nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [ neovimConfig ];
      };
    in
    {
      # packages.${system}.my-neovim = customNeovim.neovim;

      packages."x86_64-linux".default = (
        nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [ packages/neovim/nvf-main.nix ];
        }).neovim;
>>>>>>> 089d74e589bca5252d46dcbffe89335c8485515b
=======

    customNeovim = nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [neovimConfig];
    };
  in {
    packages."x86_64-linux".default =
      (
        nvf.lib.neovimConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          modules = [packages/neovim/nvf-main.nix];
        }
      )
      .neovim;
>>>>>>> tmp

    nixosConfigurations = {
      snowflake = lib.nixosSystem {
        inherit system;
<<<<<<< HEAD
        specialArgs = {inherit inputs;};
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          # inputs.agenix.nixosModules.default

<<<<<<< HEAD
          system/snowflake/disko.nix
          system/snowflake/configuration.nix
        ];
=======
            system/snowflake/disko.nix
            system/snowflake/configuration.nix
          ];
=======
        specialArgs = {
          inherit inputs;
>>>>>>> tmp
        };
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          # inputs.agenix.nixosModules.default

<<<<<<< HEAD
            { home.packages = [ customNeovim.neovim ]; }
          ];
        };
>>>>>>> 089d74e589bca5252d46dcbffe89335c8485515b
=======
          system/snowflake/disko.nix
          system/snowflake/configuration.nix

	  nixos-hardware.nixosModules.asus-zephyrus-ga402

	   {environment.systemPackages = [customNeovim.neovim];}
        ];
>>>>>>> tmp
      };
    };
    homeConfigurations = {
      quil = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs;};
        modules = [
          users/quil/home.nix

          {home.packages = [customNeovim.neovim];}
        ];
      };
    };
  };
}

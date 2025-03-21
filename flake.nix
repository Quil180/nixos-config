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

    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Stylix for Theming
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nvf,
    nixos-hardware,
    stylix,
    ...
  } @ inputs: let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # neovim config package management
    neovimConfig = {
      imports = [
        packages/neovim/nvf-main.nix
      ];
    };
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

    nixosConfigurations = {
      snowflake = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          # inputs.agenix.nixosModules.default

          system/snowflake/disko.nix
          system/snowflake/configuration.nix

          nixos-hardware.nixosModules.asus-zephyrus-ga402

          {environment.systemPackages = [customNeovim.neovim];}
        ];
      };
    };
    homeConfigurations = {
      quil = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs;};
        modules = [
          users/quil/home.nix

          stylix.homeManagerModules.stylix
          {home.packages = [customNeovim.neovim];}
        ];
      };
    };
  };
}

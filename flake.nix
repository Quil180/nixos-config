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

    # Cursor of choice
    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For G14 hardware configuration
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    # Latest Hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };

    # Hyprland Plugins
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Stylix for Theming
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flatpak declerative installation
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    };

    # For rust usage
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Used for hyprland
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };

    # Latest version of neovim
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    winboat = {
      url = "github:Rexcrazy804/winboat?ref=fix-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixos-hardware,
    stylix,
    # nix-flatpak,
    rust-overlay,
    hyprland,
    determinate,
    ...
  } @ inputs: let
    username = "quil";
    dotfilesDir = "/home/${username}/.dotfiles";
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      snowflake = lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs system username dotfilesDir;
        };
        modules = [
          inputs.disko.nixosModules.default
          inputs.impermanence.nixosModules.impermanence
          inputs.agenix.nixosModules.default
          nixos-hardware.nixosModules.asus-zephyrus-ga402
          determinate.nixosModules.default

          system/snowflake/disko.nix
          system/snowflake/configuration.nix
        ];
      };
    };
    homeConfigurations = {
      quil = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system username dotfilesDir;
        };
        modules = [
          users/${username}/home.nix

          stylix.homeModules.stylix
          hyprland.homeManagerModules.default
          {
            nixpkgs.overlays = [rust-overlay.overlays.default];
          }
        ];
      };
    };
  };
}

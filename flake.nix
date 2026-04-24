{
  description = "Nixos config flake (Dendritic Pattern)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    winboat = {
      url = "github:Rexcrazy804/winboat?ref=fix-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, lib, ... }:
      {
        imports = [
          (inputs.import-tree ./system)
          (inputs.import-tree ./users)
        ];

        options = {
          flake.homeModules = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.unspecified;
            default = { };
          };
          configurations = {
            nixos = lib.mkOption {
              type = lib.types.lazyAttrsOf (
                lib.types.submodule {
                  options.module = lib.mkOption {
                    type = lib.types.deferredModule;
                  };
                }
              );
            };
            home = lib.mkOption {
              type = lib.types.lazyAttrsOf (
                lib.types.submodule {
                  options.module = lib.mkOption {
                    type = lib.types.deferredModule;
                  };
                }
              );
            };
          };
        };

        config = {
          _module.args = {
            topConfig = config;
          };

          systems = [
            "x86_64-linux"
            "aarch64-linux"
          ];

          flake.nixosConfigurations = lib.mapAttrs (
            name: host:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs;
                username = "quil";
                system = "x86_64-linux";
              };
              modules = [
                host.module
                inputs.agenix.nixosModules.default
                inputs.disko.nixosModules.disko
                inputs.impermanence.nixosModules.impermanence
                inputs.stylix.nixosModules.stylix
                inputs.nix-flatpak.nixosModules.nix-flatpak
              ];
            }
          ) config.configurations.nixos;

          flake.homeConfigurations = lib.mapAttrs (
            name: user:
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages."x86_64-linux";
              extraSpecialArgs = {
                inherit inputs;
                username = name;
                system = "x86_64-linux";
                dotfilesDir = "/home/quil/.dotfiles";
              };
              modules = [
                user.module
                inputs.stylix.homeModules.stylix
                inputs.hyprland.homeManagerModules.default
                inputs.nixcord.homeModules.nixcord
                "${inputs.impermanence}/home-manager.nix"
                inputs.nix-flatpak.homeManagerModules.nix-flatpak
              ];
            }
          ) config.configurations.home;
        };
      }
    );
}

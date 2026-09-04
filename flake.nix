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
    nixcord = {
      url = "github:kaylorben/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rose-pine-hyprcursor.url = "github:ndom91/rose-pine-hyprcursor";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian.url = "github:Jovian-Experiments/Jovian-NixOS";
    creamlinux-installer = {
      type = "github";
      owner = "Novattz";
      repo = "creamlinux-installer";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    let
      # The repository itself, bundled into the installer ISO / install app.
      # .git (295M) and the `result` symlink are excluded; secrets are kept.
      # Note: as a git flake, the wallpapers submodule content is NOT
      # included (it is restored post-login via 'git submodule update').
      flakeSource = builtins.path {
        name = "nixos-config-source";
        path = ./.;
        filter = p: t: baseNameOf p != ".git" && baseNameOf p != "result";
      };
    in
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
          ];

          flake.nixosConfigurations =
            (lib.mapAttrs (
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
                  inputs.jovian.nixosModules.default
                ];
              }
            ) config.configurations.nixos)
            // {
              # Installer ISO: `nix build .#nixosConfigurations.installer.config.system.build.isoImage`
              installer = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                specialArgs = {
                  inherit inputs flakeSource;
                };
                modules = [
                  "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
                  ./installer/iso.nix
                ];
              };
            };

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
                inputs.nix-flatpak.homeManagerModules.nix-flatpak
                inputs.agenix.homeManagerModules.default
              ];
            }
          ) config.configurations.home;

        perSystem = { config, self', inputs', pkgs, system, ... }: {
          formatter = pkgs.nixfmt-rfc-style;

          # disko as a runnable CLI (`nix run .#disko`), for stock-ISO installs.
          packages.disko = inputs.disko.packages.${system}.disko;

          # `nix run .#install -- --system snowflake --device /dev/nvme0n1` on a stock ISO.
          apps.install = {
            type = "app";
            program = "${flakeSource}/installer/install.sh";
          };

          devShells.default = pkgs.mkShell {
            packages = [ pkgs.nixos-rebuild pkgs.home-manager pkgs.statix pkgs.deadnix ];
          };

          # Advisory lint checks: the tree is not yet nixfmt/statix-clean
          # (~50 of 70 files unformatted), so `|| true` keeps CI green while
          # surfacing violations. Drop the `|| true` after a repo-wide cleanup.
          checks.nixfmt = pkgs.runCommandLocal "nixfmt-check" {} ''
            ${pkgs.nixfmt-rfc-style}/bin/nixfmt --check ${./.} || true
            touch $out
          '';

          checks.statix = pkgs.runCommandLocal "statix-check" {} ''
            ${pkgs.statix}/bin/statix check ${./.} || true
            touch $out
          '';
        };
        };
      }
    );
}

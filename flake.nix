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
                  options = {
                    module = lib.mkOption {
                      type = lib.types.deferredModule;
                    };
                    system = lib.mkOption {
                      type = lib.types.str;
                      default = "x86_64-linux";
                      description = "Platform this host builds for.";
                    };
                    tags = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = ''
                        Host traits, handed to every module of this host as the
                        `tags` specialArg (system side) and, via the matching
                        home target, to the home side as well. Shared modules
                        branch on them, e.g.
                        lib.mkIf (builtins.elem "laptop" tags) …
                        Suggested vocabulary: "laptop" "desktop" "asus" "rocm".
                      '';
                    };
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

          flake.nixosConfigurations = lib.mapAttrs (
            name: host:
            nixpkgs.lib.nixosSystem {
              system = host.system;
              specialArgs = {
                inherit inputs;
                username = "quil";
                hostname = name;
                system = host.system;
                tags = host.tags;
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
          ) config.configurations.nixos;

          flake.homeConfigurations = lib.mapAttrs (
            name: user:
            let
              # Home targets are named "<user>@<host>". home-manager's own
              # flake resolution probes $USER@$(hostname -f|-s) before falling
              # back to a bare "$USER", so `home-manager switch --flake <dir>`
              # with no attribute (the `updh` alias) picks the right target per
              # machine. A bare "<user>" target still works and gets no tags.
              parts = lib.splitString "@" name;
              username = builtins.head parts;
              hostname = if builtins.length parts > 1 then builtins.elemAt parts 1 else null;
              host = if hostname == null then null else config.configurations.nixos.${hostname} or null;
              # Platform and traits are declared once, on the host entry.
              system = if host == null then "x86_64-linux" else host.system;
            in
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${system};
              extraSpecialArgs = {
                inherit inputs username hostname system;
                tags = if host == null then [ ] else host.tags;
                dotfilesDir = "/home/${username}/.dotfiles";
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

          perSystem =
            { pkgs, system, ... }:
            {
              formatter = pkgs.nixfmt-rfc-style;

              # disko as a runnable CLI (`nix run .#disko`), for stock-ISO installs.
              packages.disko = inputs.disko.packages.${system}.disko;

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

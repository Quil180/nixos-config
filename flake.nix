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
      url = "github:nix-community/stylix";
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

        config =
          let
            nixosConfigurations = lib.mapAttrs (
              name: host:
              nixpkgs.lib.nixosSystem {
                inherit (host) system;
                specialArgs = {
                  inherit inputs;
                  username = "quil";
                  hostname = name;
                  inherit (host) system;
                  inherit (host) tags;
                };
                modules = [
                  host.module
                  # Only what every host (desktop, VM, LXC) uses. Feature-specific
                  # upstream modules are imported by the module that needs them:
                  # stylix by `workstation`, jovian by `games`, impermanence by
                  # `persist`.
                  inputs.agenix.nixosModules.default
                  inputs.disko.nixosModules.disko
                ];
              }
            ) config.configurations.nixos;

            homeConfigurations = lib.mapAttrs (

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
                  inherit
                    inputs
                    username
                    hostname
                    system
                    ;
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

            # Device-overridable disko configs for the installer: disko's
            # --argstr device threads into this function (cli.nix builds it
            # with --argstr), so `nixos-install-drive --device /dev/sda` can
            # retarget a host whose module hardcodes /dev/nvme0n1. The disko
            # CLI prefers diskoConfigurations over the nixosConfigurations
            # path when both exist.
            diskoConfigurations = lib.mapAttrs (
              name: _host:
              {
                device ? "/dev/nvme0n1",
                lib,
                ...
              }:
              (builtins.getAttr name nixosConfigurations).config.disko.devices
              // {
                disk.sdb.device = lib.mkForce device;
              }
            ) config.configurations.nixos;

            # The offline installer ISO: the same installer module, but with
            # the personal machines' closures, their disko scripts and the
            # home-manager activation packages preloaded so an install can
            # run with no network at all. Built HERE (the outputs layer)
            # because the preloaded store contents are computed from the
            # nixosConfigurations/homeConfigurations attrsets above — doing
            # that inside a configurations.nixos module would evaluate the
            # flake outputs while config.flake.nixosConfigurations is still
            # being enumerated (eval-order cycle).
            offlineHosts = [
              "snowflake"
              "moraine"
            ];
            storePath = drv: builtins.unsafeDiscardStringContext (builtins.toString drv);
            toplevelOf = name: storePath nixosConfigurations.${name}.config.system.build.toplevel;
            diskoScriptOf = name: storePath nixosConfigurations.${name}.config.system.build.destroyFormatMount;
            activationOf = name: storePath homeConfigurations."quil@${name}".activationPackage;
            deviceOf = name: nixosConfigurations.${name}.config.disko.devices.disk.sdb.device;

            # Lines the installer's `offline_path` parser understands:
            #   <type> <key> <store-path-or-device>
            offlineTargetsText =
              builtins.concatStringsSep "\n" (
                builtins.concatLists (
                  map (name: [
                    "toplevel ${name} ${toplevelOf name}"
                    "disko ${name} ${diskoScriptOf name}"
                    "home quil@${name} ${activationOf name}"
                    "device ${name} ${deviceOf name}"
                  ]) offlineHosts
                )
              )
              + "\n";

            offlineStoreContents = builtins.concatLists (
              map (name: [
                nixosConfigurations.${name}.config.system.build.toplevel
                nixosConfigurations.${name}.config.system.build.destroyFormatMount
                homeConfigurations."quil@${name}".activationPackage
              ]) offlineHosts
            );

            # Same wiring as the per-host mapAttrs above, so the offline
            # target also gets agenix + disko modules.
            installerOfflineSystem = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = {
                inherit inputs;
                username = "quil";
                hostname = "installer-offline";
                system = "x86_64-linux";
                tags = [ ];
              };
              modules = [
                ((import ./lib/installer-module.nix) {
                  storeContents = offlineStoreContents;
                  targetsText = offlineTargetsText;
                })
                inputs.agenix.nixosModules.default
                inputs.disko.nixosModules.disko
              ];
            };
          in
          {
            _module.args = {
              topConfig = config;
            };

            systems = [
              "x86_64-linux"
            ];

            flake = {
              inherit
                homeConfigurations
                diskoConfigurations
                ;

              # Map-attrs hosts plus the offline installer (which can't live
              # in configurations.nixos for the eval-order reason above). CI
              # reads this attrNames list, so the installer lands on the
              # matrix automatically.
              nixosConfigurations = nixosConfigurations // {
                installer-offline = installerOfflineSystem;
              };
            };

            perSystem =
              { pkgs, system, ... }:
              let
                # The one-command installer (system/installer/nixos-install-drive.sh).
                installPkg = (import ./lib/install-script.nix) {
                  inherit pkgs lib;
                  diskoPkg = inputs.disko.packages.${system}.disko;
                };
              in
              {
                formatter = pkgs.nixfmt;

                # disko as a runnable CLI (`nix run .#disko`), for stock-ISO installs.
                packages.disko = inputs.disko.packages.${system}.disko;

                # The one-command installer for fresh machines, e.g. from a stock
                # NixOS live ISO:
                #   nix run github:Quil180/nixos-config#install -- --host moraine
                packages.install = installPkg;

                # Installer ISOs (`nix build .#iso` / `nix build .#iso-offline`).
                packages.iso = nixosConfigurations.installer.config.system.build.isoImage;
                packages.iso-offline = installerOfflineSystem.config.system.build.isoImage;

                apps.install = {
                  type = "app";
                  program = "${installPkg}/bin/nixos-install-drive";
                  meta.description = "Installer for fresh machines to install NixOS";
                };

                devShells.default = pkgs.mkShell {
                  packages = [
                    pkgs.nixos-rebuild
                    pkgs.home-manager
                    pkgs.statix
                    pkgs.deadnix
                  ];
                };

                # Lint checks, enforced: `nix flake check` (and CI) fail on any
                # unformatted file, statix warning or unused binding. Fix with
                # `nix fmt`, `statix fix` and `deadnix -e`.
                checks.nixfmt = pkgs.runCommandLocal "nixfmt-check" { } ''
                  find ${./.} -name '*.nix' -exec ${pkgs.nixfmt}/bin/nixfmt --check {} +
                  touch $out
                '';

                checks.statix = pkgs.runCommandLocal "statix-check" { } ''
                  ${pkgs.statix}/bin/statix check --config ${./statix.toml} ${./.}
                  touch $out
                '';

                checks.deadnix = pkgs.runCommandLocal "deadnix-check" { } ''
                  ${pkgs.deadnix}/bin/deadnix --fail ${./.}
                  touch $out
                '';
              };
          };
      }
    );
}

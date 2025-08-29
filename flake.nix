{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nvf.url = "github:notashelf/nvf";
    rust-overlay.url = "github:oxalica/rust-overlay";
    stylix.url = "github:danth/stylix";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins.url = "github:hyprwm/hyprland-plugins";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nix-flatpak = { url = "github:gmodena/nix-flatpak/?ref=v0.6.0"; };
    rose-pine-hyprcursor = { url = "github:ndom91/rose-pine-hyprcursor"; };
    split-monitor-workspaces = { url = "github:Duckonaut/split-monitor-workspaces"; inputs.hyprland.follows = "hyprland"; };
    nixcord = { url = "github:kaylorben/nixcord"; inputs.nixpkgs.follows = "nixpkgs"; };
    firefox-addons = { url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons"; inputs.nixpkgs.follows = "nixpkgs"; };
    impermanence = { url = "github:nix-community/impermanence"; };
    agenix = { url = "github:ryantm/agenix"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nvf, rust-overlay, stylix, hyprland, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
          (self: super: let
            pname = "lsprotocol";
            pinnedVersion = "0.1.0";
          in {
            python3Packages = let
              py = super.python3Packages;
            in py // {
              lsprotocol = py.buildPythonPackage rec {
                inherit pname;
                version = pinnedVersion;
                src = py.fetchPypi { inherit pname version; };
                doCheck = false;
                meta = with py.lib; { description = "Pinned lsprotocol for pygls"; };
              };

              pygls = py.pygls.overrideAttrs (old: {
                doCheck = false;
                checkPhase = ''
                  echo "Skipping pygls tests via overlay"
                '';
              });

              jedi-language-server = py.jedi-language-server.overrideAttrs (old: {
                doCheck = false;
              });
            };
          })
        ];
      };
    in {
      homeConfigurations = {
        quil = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./users/quil/home.nix
            stylix.homeModules.stylix
            hyprland.homeManagerModules.default
          ];
        };
      };

      packages."x86_64-linux".default = (nvf.lib.neovimConfiguration {
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        modules = [ ./packages/neovim/nvf-main.nix ];
      }).neovim;
    };
}

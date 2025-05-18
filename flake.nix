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

    # flatpak declerative installation
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    creamlinux = {
      url = "github:Novattz/creamlinux-installer";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nvf,
    nixos-hardware,
    stylix,
    nix-flatpak,
    rust-overlay,
    split-monitor-workspaces,
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
          nix-flatpak.nixosModules.nix-flatpak
          nixos-hardware.nixosModules.asus-zephyrus-ga402

          system/snowflake/disko.nix
          system/snowflake/configuration.nix

          {
            environment.systemPackages = [customNeovim.neovim];
          }
        ];
      };
    };
    homeConfigurations = {
      quil = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs;};
        modules = [
          users/quil/home.nix

          stylix.homeModules.stylix
          {
            home.packages = [customNeovim.neovim];
            nixpkgs.overlays = [rust-overlay.overlays.default];
          }
        ];
      };
    };
  };
}

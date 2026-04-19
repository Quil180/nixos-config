{ inputs, ... }:

{
  flake.homeConfigurations.quil = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
    extraSpecialArgs = {
      inherit inputs;
      system = "x86_64-linux";
      username = "quil";
      dotfilesDir = "/home/quil/.dotfiles";
    };
    modules = [
      ./home.nix

      inputs.stylix.homeModules.stylix
      inputs.hyprland.homeManagerModules.default
      {
        nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
      }
    ];
  };
}

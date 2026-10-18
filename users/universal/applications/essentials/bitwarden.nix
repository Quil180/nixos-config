_: {
  flake.homeModules.bitwarden = { pkgs, ... }: {
    home.packages = with pkgs; [
      bitwarden-desktop
    ];
  };
}

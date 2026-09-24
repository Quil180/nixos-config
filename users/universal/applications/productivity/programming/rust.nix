_: {
  flake.homeModules.rust = { pkgs, ... }: {
    home.packages = with pkgs; [
      rustup
    ];
  };
}

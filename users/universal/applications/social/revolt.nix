_: {
  flake.homeModules.revolt = { pkgs, ... }: {
    home.packages = with pkgs; [
      revolt-desktop
    ];
  };
}

_: {
  flake.homeModules.zoom = { pkgs, ... }: {
    home.packages = with pkgs; [
      zoom-us
    ];
  };
}

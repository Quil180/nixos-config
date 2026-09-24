_: {
  flake.homeModules.cpp = { pkgs, ... }: {
    home.packages = with pkgs; [
      gcc
      cmake
    ];
  };
}

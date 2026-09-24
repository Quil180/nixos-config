_: {
  flake.homeModules.creamlinux =
    # this is only used for testing of already owned dlcs and ensuring the files are correct. I do not condone nor pirate any games.
    {
      pkgs,
      inputs,
      ...
    }:
    {
      home.packages = [
        (import inputs.creamlinux-installer { inherit pkgs; })
      ];
    };
}

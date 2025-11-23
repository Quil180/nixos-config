# this is only used for testing of already owned dlcs and ensuring the files are correct. I do not condone nor pirate any games.
{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    inputs.creamlinux.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}

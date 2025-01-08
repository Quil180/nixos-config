{
  pkgs,
  lib,
  ...
}: {
  vim = {
    languages = {
      nix = {
        enable = true;
        format.enable = true;
      };
      clang = {
        # C/C++
        enable = true;
      };
      java = {
        enable = true;
      };
      bash = {
        enable = true;
        format.enable = true;
      };
      python = {
        enable = true;
        format.enable = true;
      };
    };
  };
}

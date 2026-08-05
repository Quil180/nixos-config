{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.git = { config, ... }: {
    # git config
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
      };
      includes = [
        {
          path = "${config.home.homeDirectory}/.local/state/git_identity";
        }
      ];
      lfs.enable = true;
    };

    programs.gh = {
      enable = true;
    };
  };
}

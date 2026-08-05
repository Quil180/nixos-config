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
        { path = config.age.secrets.git_identity.path; }
      ];
      lfs.enable = true;
    };

    programs.gh = {
      enable = true;
    };
  };
}

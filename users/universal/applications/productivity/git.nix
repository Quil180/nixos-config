_: {
  flake.homeModules.git = { config, ... }: {
    # gh's login. (Not .local/state/git_identity: agenix recreates that
    # symlink on every activation.)
    persist.directories = [ ".config/gh" ];

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

    home.shellAliases = {
      g = "git";
    };
  };
}

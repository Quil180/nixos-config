_: {
  flake.homeModules.git = { config, ... }: {
    # gh's login, and the agenix-decrypted identity included below.
    persist.directories = [ ".config/gh" ];
    persist.files = [ ".local/state/git_identity" ];

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

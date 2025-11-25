{...}: {
  # git config
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
    };
    includes = [
      { path = "/run/agenix/git_identity"; }
    ];
    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
  };
}

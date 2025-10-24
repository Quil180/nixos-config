{...}: {
  # git config
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      user = {
        name = "Quil";
        email = "quil180gaming@gmail.com";
      };
    };
    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
  };
}

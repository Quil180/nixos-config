{...}: {
  # git config
  programs.git = {
    enable = true;
    userName = "Quil";
    userEmail = "quil180gaming@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
  };
}

{pkgs, ...}:

{
  # git config
  programs.git = {
    enable = true;
    userName = "Quil";
    userEmail = "quil180gaming@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}

{pkgs, ...}:

{
  programs.ranger = {
    enable = true;
    plugins = {
      # zoxide
      name = "zoxide";
      src = builtins.fetchGit {
        url = "https://github.com/jchook/ranger-zoxide.git";
      };
    };
    mappings = {
      z = "z%space";
    };
  };
}

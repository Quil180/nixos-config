{pkgs, lib, ...}:{
  vim.binds.whichKey = {
    enable = true;
    setupOpts = {
      replace = {
        "<CR>" = "\ret";
        "<leader>" = "<space>";
      };
    };
  };
}

{...}: {
  imports = [
    ./languages.nix
    ./keymaps.nix

    modules/dashboard.nix
    modules/side-tree.nix
    modules/color-indents.nix
    modules/top-bar.nix
    modules/terminal.nix
    modules/help-keys.nix
  ];

  vim = {
    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    autocomplete.nvim-cmp.enable = true;

    languages = {
      enableLSP = true;
      enableTreesitter = true;
      enableFormat = true;
    };

    options = {
      tabstop = 2;
      shiftwidth = 2;
      wrap = false;
    };
  };
}

{pkgs, ...}:

{
  imports = [
    ./plugins
  ];

  programs.nixvim = {
    # colorschemes.catppuccin.enable = true;

    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    clipboard = {
      # Use system clipboard
      register = "unnamedplus";

      providers.wl-copy.enable = true;
    };

    opts = {
      updatetime = 100;
      relativenumber = true;
      number = true;
      hidden = true;
      splitbelow = true;
      splitright = true;
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      autoindent = true;
      termguicolors = true;
      spell = false;
      wrap = false;
      smartcase = true;
      swapfile = false;
      textwidth = 0;
      undofile = true;
      ignorecase = true;
      incsearch = true;
    };
  };
}

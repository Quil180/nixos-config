{...}: {
  # to add a keymap use the following template:
  #    {
  #      key = "";
  #      mode = ""; # Normal or Visual or Command
  #      action = "";
  #    }
  vim.keymaps = [
    # default keybindings
    {
      key = ";";
      mode = "n";
      action = ":";
    }
    {
      key = "<leader>s";
      mode = "n";
      action = "<Cmd>w<CR>";
    }
    {
      key = "<leader>e";
      mode = "n";
      action = "<Cmd>wqa<CR>";
    }
    {
      key = "<leader>q";
      mode = "n";
      action = "<Cmd>q<CR>";
    }
    {
      key = "<leader>h";
      mode = "n";
      action = "<Cmd>nohl<CR>";
    }

    # file-tree keybinding
    {
      key = "<leader>t";
      mode = "n";
      action = "<Cmd>Neotree toggle<CR>";
    }

    # Format code command
    {
      key = "<leader>f";
      mode = "n";
      action = "<cmd>lua vim.lsp.buf.format()<CR>";
    }
  ];
}

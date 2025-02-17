{...}: {
  vim.tabline = {
    nvimBufferline = {
      enable = true;
      mappings = {
        closeCurrent = "<leader>bc";
        pick = "<leader>bp";
        movePrevious = "<leader>bmb";
        moveNext = "<leader>bmn";
        cycleNext = "<leader>bn";
        cyclePrevious = "<leader>bb";
      };
    };
  };
}

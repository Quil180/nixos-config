{...}: {
  vim.assistant.copilot = {
    enable = true;
    cmp.enable = true;
    mappings.panel = {
      open = "<leader>go";
    };
  };
}

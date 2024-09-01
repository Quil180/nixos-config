return {
  'lewis6991/gitsigns.nvim',
  config = function()
    require("gitsigns").setup()

    vim.keymap.set('n', '<Leader>gp', ":Gitsigns preview_hunk<CR>", { desc = 'Preview changes to Github'})
  end
}

return { -- the file system tree to the left
  "is0n/fm-nvim",
  config = function()
    vim.keymap.set('n', '<leader>x', ":Ranger<CR>", { desc = 'Open Ranger' })
  end
}

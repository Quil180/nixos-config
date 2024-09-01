return {
  "christoomey/vim-tmux-navigator",
  config = function()
    vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = '[W]indow Split [V]ertically' }) -- split window vertically
    vim.keymap.set('n', '<leader>wh', '<C-w>s', { desc = '[W]indow Split [H]orizontally' }) -- split horizontally
    vim.keymap.set('n', '<leader>we', '<C-w>=', { desc = '[W]indow Split [E]qually' })  -- make windows equal
    vim.keymap.set('n', '<leader>wc', ':close<CR>', { desc = '[W]indow [C]lose' })      -- close current window
  end
}

return {
  'romgrk/barbar.nvim',
  dependencies = {
    'lewis6991/gitsigns.nvim',     -- OPTIONAL: for git status
    'nvim-tree/nvim-web-devicons', -- OPTIONAL: for file icons
    'echasnovski/mini.nvim', -- for mini icons
  },
  config = function()
    init = function() vim.g.barbar_auto_setup = false end
    --opts = {
    -- lazy.nvim will automatically call setup for you. put your options here, anything missing will use the default:
    -- animation = true,
    -- insert_at_start = true,
    -- …etc.
    --}
    vim.keymap.set('n', '<Leader>bc', ":BufferClose<CR>", { desc = '[B]uffer [C]lose' })
    vim.keymap.set('n', '<Leader>bn', ":BufferNext<CR>", { desc = '[B]uffer [N]ext' })
    vim.keymap.set('n', '<Leader>bb', ":BufferPrevious<CR>", { desc = '[B]uffer [B]ack' })
  end,
}

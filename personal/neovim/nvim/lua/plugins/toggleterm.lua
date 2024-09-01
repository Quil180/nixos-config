return {
  'akinsho/toggleterm.nvim',
  config = function()
    require("toggleterm").setup()

    -- key presses
    vim.keymap.set('n', '<leader>tb', ":ToggleTerm size=10 direction=horizontal<CR>", { desc = 'Toggle [T]erminal [B]ottom' })

  end
}

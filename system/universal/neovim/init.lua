-- Basic Options
vim.opt.number         = true  -- Line Numbers on Left
vim.opt.relativenumber = true  -- Relative Numbers on Left
vim.opt.wrap           = false -- Disabling Wrapping
vim.opt.tabstop        = 2     -- Tabs are 2 Spaces
vim.opt.shiftwidth     = 2     -- Tabs are 2 Spaces
vim.opt.swapfile       = false -- Disabling swap file

-- Setting Leader Key to <SPACE>
vim.g.mapleader = " "

-- Keybinds Below
-- Source Current File
vim.keymap.set('n', '<leader>o', ':update<CR>:source<CR>')
-- Save Current File (assuming changes made)
vim.keymap.set('n', '<leader>s', ':update<CR>')
-- Quit NeoVim
vim.keymap.set('n', '<leader>q', ':quit<CR>')

-- Copy/Cut
vim.keymap.set({'n', 'v', 'i'}, '<C-c>', '"+y')
vim.keymap.set({'n', 'v', 'i'}, '<C-d>', '"+d')

-- Package Management


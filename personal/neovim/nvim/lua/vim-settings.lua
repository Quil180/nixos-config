-- setting up that 2 spaces is a tab
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- setting up my leader to be space
vim.g.mapleader = " "

-- nvim specific options
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.formatoptions:append("t")

-- nvim specific keybinds
vim.keymap.set('n', ';', ":", {})
vim.keymap.set('n', '<leader>s', ":w<CR>", { desc='[W]rite File' })
vim.keymap.set('n', '<leader>e', ":wqa<CR>", { desc='[E]xit Nvim and Save' })
vim.keymap.set('n', '<leader>q', ":q<CR>", { desc='[Q]uit' })
vim.keymap.set('n', '<leader>l', ":Lazy<CR>", { desc='Open [L]azy' })
vim.keymap.set('n', '<leader>h', ':nohl<CR>', { desc='No [H]ighlights' })
vim.keymap.set('n', '<leader>m1', '@q', { desc='Use [M]acro [1]' })

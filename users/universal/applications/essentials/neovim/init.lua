-- Basic Options
vim.o.number         = true      -- Line Numbers on Left
vim.o.relativenumber = true      -- Relative Numbers on Left
vim.o.wrap           = false     -- Disabling Wrapping
vim.o.tabstop        = 2         -- Tabs are 2 Spaces
vim.o.shiftwidth     = 2         -- Tabs are 2 Spaces
vim.o.swapfile       = false     -- Disabling swap file
vim.o.signcolumn     = "yes"     -- Making a sign column
vim.o.winborder      = "rounded" -- rounded borders

-- Package Management
vim.pack.add({
	-- Color Schemes
	{ src = "https://github.com/catppuccin/nvim" },
	{ src = "https://github.com/Mofiqul/dracula.nvim" },
	-- Language Server Protocols
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	-- Telescoping Files
	{ src = "https://github.com/echasnovski/mini.pick" },
	-- LaTeX Preview/AutoCompiling (make sure you have arara installed)
	{ src = "https://github.com/lervag/vimtex" },
	-- Shows what keybinds exist after pressing leader
	{ src = "https://github.com/folke/which-key.nvim" },
})

-- Enabling mini.pick
require "mini.pick".setup()

-- Vimtex Setup
vim.cmd(":filetype plugin on")
vim.cmd(":filetype indent on")
vim.cmd("syntax enable")
vim.g.vimtex_view_method = 'zathura'

-- Color Scheme (Uncomment the one I want)
-- vim.cmd("colorscheme catppuccin")
-- vim.cmd("colorscheme dracula")
vim.cmd("colorscheme dracula-soft")
vim.cmd(":hi statusline guibg=NONE") -- transparent status line (MUST BE AFTER COLOR SCHEMES)

-- Setting Leader Key to <SPACE>
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Keybinds Below
-- Source Current File
vim.keymap.set('n', '<leader>o', ':update<CR>:source<CR>', { desc = '[O]h I\'ve updated my config' })
-- Save Current File (assuming changes made)
vim.keymap.set('n', '<leader>s', ':update<CR>', { desc = '[S]ave' })
-- Quit NeoVim
vim.keymap.set('n', '<leader>q', ':quit<CR>', { desc = '[Q]uit' })
-- Copy/Cut
vim.keymap.set({ 'n', 'v', 'i' }, '<C-c>', '"+y', { desc = 'Copy' })
vim.keymap.set({ 'n', 'v', 'i' }, '<C-d>', '"+d', { desc = 'Cut' })
-- Formatting
vim.keymap.set('n', '<leader>bf', vim.lsp.buf.format, { desc = '[B]uffer [F]ormat' })
-- Find a File (mini.pick)
vim.keymap.set('n', '<leader>f', ':Pick files<CR>', { desc = '[F]ind a file' })
-- Find a keybind (mini.pick)
vim.keymap.set('n', '<leader>h', ':Pick help<CR>', { desc = '[H]elp me find a command' })
-- Hovering
vim.keymap.set('n', 'W', vim.lsp.buf.hover, { desc = '[W]hat is this?' })


-- LSP Languages Wanted!
vim.lsp.enable({
	"lua_ls",       -- lua
	"texlab",       -- latex
	"rust-analyzer", -- rust
	"clangd",       -- C/C++
	"verible",      -- SystemVerilog
	"vhdl_ls",      -- VHDL
	"basedpyright", -- Python Server
	"ruff",         -- Python Linter/Formatter
	"nixd",         -- Nix
})

-- Autocomplete with tab
vim.api.nvim_create_autocmd('LspAttach', {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method('textDocument/completion') then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})
vim.cmd("set completeopt+=noselect")

-- Setting macros for later on
local opt          = vim.opt
local map          = vim.keymap.set

-- Basic Options
opt.number         = true      -- Line Numbers on Left
opt.relativenumber = true      -- Relative Numbers on Left
opt.wrap           = false     -- Disabling Wrapping
opt.tabstop        = 2         -- Tabs are 2 Spaces
opt.shiftwidth     = 2         -- Tabs are 2 Spaces
opt.swapfile       = false     -- Disabling swap file
opt.signcolumn     = "yes"     -- Making a sign column
opt.winborder      = "rounded" -- rounded borders
opt.termguicolors  = true      -- enabling terminal gui colors

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
map('n', '<leader>o', ':update<CR>:source<CR>', { desc = '[O]h I\'ve updated my config' })
-- Save Current File (assuming changes made)
map('n', '<leader>s', ':update<CR>', { desc = '[S]ave' })
-- Quit NeoVim
map('n', '<leader>q', ':quit<CR>', { desc = '[Q]uit' })
-- Copy/Cut
map({ 'n', 'v', 'i' }, '<C-c>', '"+y', { desc = 'Copy' })
map({ 'n', 'v', 'i' }, '<C-d>', '"+d', { desc = 'Cut' })
map({ 'n', 'v', 'i' }, '<leader>y', '"+y', { desc = 'Copy, but different' })
map({ 'n', 'v', 'i' }, '<leader>d', '"+d', { desc = 'Cut, but different' })
-- Formatting
map('n', '<leader>bf', vim.lsp.buf.format, { desc = '[B]uffer [F]ormat' })
-- Find a File (mini.pick)
map('n', '<leader>f', ':Pick files<CR>', { desc = '[F]ind a file' })
-- Find a keybind (mini.pick)
map('n', '<leader>h', ':Pick help<CR>', { desc = '[H]elp me find a command' })
-- Hovering
map('n', 'W', vim.lsp.buf.hover, { desc = '[W]hat is this?' })
-- Terminal!
map('n', '<leader>tv', ':vs | term<CR>', { desc = '[T]erminal [V]ertical' })
map('n', '<leader>tf', ':tabnew | term<CR>', { desc = '[T]erminal [F]ullscreen' })
map('t', '<C-o>', [[<C-\><C-n>]], { desc = '[T]erminal [E]xit' })
-- Tabs!
map('n', '<leader>tm', ':tabnew<CR>', { desc = '[T]ab [M]ake' })
map('n', '<leader>tc', ':tabclose<CR>', { desc = '[T]ab [C]lose' })
map('n', '<leader>tn', ':tabnext<CR>', { desc = '[T]ab [N]ext' })
map('n', '<leader>tb', ':tabprevious<CR>', { desc = '[T]ab [B]ack' })
map('n', '<leader>tp', ':tabmove<CR>', { desc = '[T]ab [P]ush Back' })


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
-- Giving lua_ls where the neovim stuff is
vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			}
		}
	}
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


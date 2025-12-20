-- Setting macros for use later on
local opt          = vim.opt
local map          = vim.keymap.set

-- Basic Options
opt.number         = true      -- Line Numbers on Left
opt.relativenumber = true      -- Relative Numbers on Left
opt.wrap           = false     -- Disabling Wrapping
opt.tabstop        = 2         -- Tabs are 2 Spaces
opt.shiftwidth     = 2         -- Shifts are 2 Spaces
opt.expandtab      = true      -- Tabs are always spaces
opt.swapfile       = false     -- Disabling swap file
opt.signcolumn     = "yes"     -- Making a sign column
opt.winborder      = "rounded" -- rounded borders
opt.termguicolors  = true      -- enabling terminal gui colors

-- Indent guides
opt.list           = true
opt.listchars      = { leadmultispace = "│ ", trail = "·", tab = "→ " }

-- Package Management
vim.pack.add({
  -- Color Schemes
  { src = "https://github.com/Mofiqul/dracula.nvim" },
  -- Telescoping Files
  { src = "https://github.com/echasnovski/mini.pick" },
  -- LaTeX Preview/AutoCompiling (make sure you have arara installed)
  { src = "https://github.com/lervag/vimtex" },
  -- Shows what keybinds exist after pressing leader
  { src = "https://github.com/folke/which-key.nvim" },
  -- Simple File Explorer to get rid of Ranger Usage
  { src = "https://github.com/stevearc/oil.nvim" },
  -- Shows hex colors if specified in code
  { src = "https://github.com/brenoprata10/nvim-highlight-colors" },
  -- AI Chat/Completion (Avante - like Cursor AI)
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
  { src = "https://github.com/stevearc/dressing.nvim" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  { src = "https://github.com/yetone/avante.nvim", build = "make" },
})

-- mini.pick Setup
require "mini.pick".setup()

-- Oil Setup
require "oil".setup()

-- Vimtex Setup
vim.cmd(":filetype plugin on")
vim.cmd(":filetype indent on")
vim.cmd("syntax enable")
vim.g.vimtex_view_method = 'zathura'

-- Highlight Colors
vim.opt.termguicolors = true
require "nvim-highlight-colors".setup()

-- Avante Setup (AI like Cursor, using Ollama)
require("avante").setup({
  provider = "ollama",
  providers = {
    ollama = {
      endpoint = "http://localhost:11434",
      model = "hf.co/ibm-granite/granite-4.0-micro-GGUF:Q4_K_M",
      is_env_set = function()
        -- Check if Ollama is running
        local handle = io.popen("curl -s http://localhost:11434/api/tags 2>/dev/null")
        if handle then
          local result = handle:read("*a")
          handle:close()
          return result and result ~= ""
        end
        return false
      end,
    },
  },
  behaviour = {
    auto_suggestions = false, -- Disable auto suggestions (can be resource heavy)
    auto_set_keymaps = true,
  },
  windows = {
    position = "right",
    width = 40,
  },
})

-- Color Scheme (Uncomment the one I want)
-- vim.cmd("colorscheme catppuccin")
-- vim.cmd("colorscheme dracula")
vim.cmd("colorscheme dracula-soft")
vim.cmd(":hi statusline guibg=NONE") -- transparent status line (MUST BE AFTER COLOR SCHEMES)

-- Setting Leader Key to <SPACE>
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

-- Keybinds Below
-- Source Current File
map('n', '<leader>ou', ':update<CR>:source<CR>', { desc = '[O]h I\'ve[U]pdated my config' })
map('n', '<leader>oe', ':update<CR>:edit ~/.dotfiles/users/universal/applications/essentials/neovim/init.lua<CR>',
  { desc = '[O]h [E]dit my config' })
-- Save Current File (assuming changes made)
map('n', '<leader>s', ':update<CR>', { desc = '[S]ave' })
-- Quit NeoVim
map('n', '<leader>q', ':quit<CR>', { desc = '[Q]uit' })
-- Copy/Cut
map({ 'n', 'v', 'i' }, '<C-c>', '"+y', { desc = 'Copy' })
map({ 'n', 'v', 'i' }, '<C-d>', '"+d', { desc = 'Cut' })
map({ 'n' }, '<leader>y', '"+y', { desc = 'Copy, but different' })
map({ 'n' }, '<leader>d', '"+d', { desc = 'Cut, but different' })
-- Formatting (smart: tries LSP first, then external formatters)
local function smart_format()
  -- Map of filetypes to external formatters
  local formatters = {
    nix = { cmd = "nixfmt", args = {} },
    lua = { cmd = "stylua", args = { "-" } },
    python = { cmd = "ruff", args = { "format", "-" } },
    rust = { cmd = "rustfmt", args = {} },
  }

  local ft = vim.bo.filetype
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  -- Check if any LSP client supports formatting
  local has_lsp_format = false
  for _, client in ipairs(clients) do
    if client.supports_method("textDocument/formatting") then
      has_lsp_format = true
      break
    end
  end

  if has_lsp_format then
    vim.lsp.buf.format()
  elseif formatters[ft] then
    -- Use external formatter
    local formatter = formatters[ft]
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local input = table.concat(lines, "\n")

    local result = vim.system({ formatter.cmd, unpack(formatter.args) }, {
      stdin = input,
      text = true,
    }):wait()

    if result.code == 0 and result.stdout and result.stdout ~= "" then
      local new_lines = vim.split(result.stdout, "\n", { trimempty = false })
      -- Remove trailing empty line if present
      if new_lines[#new_lines] == "" then
        table.remove(new_lines)
      end
      vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
      vim.notify("Formatted with " .. formatter.cmd, vim.log.levels.INFO)
    elseif result.stderr and result.stderr ~= "" then
      vim.notify("Format error: " .. result.stderr, vim.log.levels.ERROR)
    end
  else
    vim.notify("No formatter available for " .. ft, vim.log.levels.WARN)
  end
end
map('n', '<leader>bf', smart_format, { desc = '[B]uffer [F]ormat' })
map('n', '<leader>bd', ':bd<CR>', { desc = '[B]uffer [D]elete' })
-- Find a File (mini.pick)
map('n', '<leader>f', ':Pick files<CR>', { desc = '[F]ind a file' })
-- Find a Piece of Text
map('n', '<leader>g', ':Pick grep_live<CR>', { desc = '[G]rep for a phrase' })
-- Find a Buffer
map('n', '<leader>bg', ':Pick buffers<CR>', { desc = '[B]uffer [G]rep' })
-- Find a keybind (mini.pick)
map('n', '<leader>h', ':Pick help<CR>', { desc = '[H]elp me find a command' })
-- Hovering
map('n', 'W', vim.lsp.buf.hover, { desc = '[W]hat is this?' })
-- map('n', 'E', vim.diagnostic.open_float, { desc = 'What\'s the [E]rror' })
vim.keymap.set('n', 'E', function()
  vim.diagnostic.config({ virtual_lines = { current_line = true }, virtual_text = false })

  vim.api.nvim_create_autocmd('CursorMoved', {
    group = vim.api.nvim_create_augroup('line-diagnostics', { clear = true }),
    callback = function()
      vim.diagnostic.config({ virtual_lines = false, virtual_text = true })
      return true
    end,
  })
end, { desc = 'What\'s the [E]rror' })
-- Terminal!
map('n', '<leader>tv', ':vsplit | term<CR>', { desc = '[T]erminal [V]ertical' })
map('n', '<leader>th', ':split | term<CR>', { desc = '[T]erminal [H]orizontal' })
map('n', '<leader>tf', ':tabnew | term<CR>', { desc = '[T]erminal [F]ullscreen' })
map('t', '<C-o>', [[<C-\><C-n>]], { desc = '[T]erminal [E]xit' })
-- Tabs!
map('n', '<leader>tm', ':tabnew<CR>', { desc = '[T]ab [M]ake' })
map('n', '<leader>tc', ':tabclose<CR>', { desc = '[T]ab [C]lose' })
map('n', '<leader>tn', ':tabnext<CR>', { desc = '[T]ab [N]ext' })
map('n', '<leader>tb', ':tabprevious<CR>', { desc = '[T]ab [B]ack' })
map('n', '<leader>tp', ':tabmove<CR>', { desc = '[T]ab [P]ush Back' })
-- Oil/File Explorer
map('n', '<leader>eo', ':split | Oil<CR>', { desc = '[E]xplorer [O]pen' })
-- opening a new horizontal window
map('n', '<leader>wv', ':vsplit<CR>', { desc = '[W]indow [V]ertical' })
map('n', '<leader>wh', ':split<CR>', { desc = '[W]indow [H]orizontal' })
map('n', '<leader>wc', ':close<CR>', { desc = '[W]indow [C]lose' })
-- AI (Avante) keybindings
map('n', '<leader>aa', ':AvanteAsk<CR>', { desc = '[A]I [A]sk' })
map('v', '<leader>aa', ':AvanteAsk<CR>', { desc = '[A]I [A]sk with selection' })
map('n', '<leader>at', ':AvanteToggle<CR>', { desc = '[A]I [T]oggle sidebar' })
map('n', '<leader>ar', ':AvanteRefresh<CR>', { desc = '[A]I [R]efresh' })
map('n', '<leader>ae', ':AvanteEdit<CR>', { desc = '[A]I [E]dit' })
map('v', '<leader>ae', ':AvanteEdit<CR>', { desc = '[A]I [E]dit selection' })
map('n', '<leader>af', ':AvanteFocus<CR>', { desc = '[A]I [F]ocus' })
map('n', '<leader>ac', ':AvanteChat<CR>', { desc = '[A]I new [C]hat' })

-- Lazygit floating terminal
local function open_lazygit()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Lazygit ',
    title_pos = 'center',
  })
  vim.fn.termopen('lazygit', {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })
  vim.cmd('startinsert')
end
map('n', '<leader>lg', open_lazygit, { desc = '[L]azy[G]it' })

-- LSP Languages Wanted!
vim.lsp.enable({
  "lua_ls",        -- lua
  "texlab",        -- latex
  "rust_analyzer", -- rust
  "clangd",        -- C/C++
  "verible",       -- SystemVerilog
  "vhdl_ls",       -- VHDL
  "basedpyright",  -- Python Server
  "ruff",          -- Python Linter/Formatter
  "nixd",          -- Nix
  "qmlls",         -- QML
})

-- Autocomplete setup
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client then
      -- Enable completion for this buffer
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      -- Set omnifunc as fallback for <C-x><C-o>
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end
  end,
})

-- Trigger completion on any text change (workaround for servers without trigger characters)
vim.api.nvim_create_autocmd('TextChangedI', {
  callback = function()
    -- Only trigger if popup menu is not visible and we have LSP clients
    if vim.fn.pumvisible() == 0 and #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
      -- Get the character before cursor
      local col = vim.fn.col('.') - 1
      if col > 0 then
        local line = vim.fn.getline('.')
        local char = line:sub(col, col)
        -- Trigger on alphanumeric, underscore, or common trigger chars
        if char:match('[%w_%.%:]') then
          -- Use feedkeys to trigger omni-completion
          local keys = vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true)
          vim.api.nvim_feedkeys(keys, 'n', false)
        end
      end
    end
  end,
})

-- Completion menu options (noselect = don't auto-select first item)
vim.opt.completeopt = { 'menu', 'menuone', 'noselect' }

-- Fixing a bug with .v and .sv fles
-- Setting the filetype for Verilog
vim.api.nvim_create_autocmd(
  { "BufNewFile", "BufRead" }, {
    pattern = { "*.v" },
    command = "set filetype=verilog",
  }
)

-- Setting the filetype for SystemVerilog
vim.api.nvim_create_autocmd(
  { "BufNewFile", "BufRead" }, {
    pattern = { "*.sv" },
    command = "set filetype=systemverilog",
  }
)

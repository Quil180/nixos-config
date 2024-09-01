return {
  'folke/which-key.nvim',
  event = 'VimEnter',
  config = function()
    -- gain access to the which key plugin
    local which_key = require('which-key')

    -- call the setup function with default properties
    which_key.setup()

    -- Register prefixes for the different key mappings we have setup previously
    which_key.add({
    { "<leader>b", group = "[B]uffer" },
    { "<leader>b_", hidden = true },
    { "<leader>c", group = "[C]ode" },
    { "<leader>c_", hidden = true },
    { "<leader>d", group = "[D]ebug" },
    { "<leader>d_", hidden = true },
    { "<leader>e", group = "[E]xplorer" },
    { "<leader>e_", hidden = true },
    { "<leader>f", group = "[F]ind" },
    { "<leader>f_", hidden = true },
    { "<leader>g", group = "[G]it" },
    { "<leader>g_", hidden = true },
    { "<leader>m", group = "[M]acro" },
    { "<leader>m_", hidden = true },
    { "<leader>w", group = "[W]indow" },
    { "<leader>w_", hidden = true },
    { "<leader>t", group = "[T]erminal" },
    { "<leader>t_", hidden = true },
  })
  end
}

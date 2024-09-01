return { -- lets you get highlighting for languages of my choosing
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- making treesitter work
    local config = require("nvim-treesitter.configs")
    config.setup({
      auto_install = true, -- installing parsers for new languages for me
      -- enabling some other features of treesitter
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}

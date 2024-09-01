-- mason nvim dap utilizes mason to automatically ensure debug adapters you want installed are installed, mason-lspconfig will not automatically install debug adapters for us
return {
  "jay-babu/mason-nvim-dap.nvim",
  config = function()
    -- ensure the following debuggers are installed
    require("mason-nvim-dap").setup({
      ensure_installed = { "java-debug-adapter", "java-test", "codelldb", "bash-debuger-adapter" },
      handlers = {
        function(config)
          -- all sources with no handler get passed here

          -- Keep original functionality
          require('mason-nvim-dap').default_setup(config)
        end,
      }
    })
  end
}

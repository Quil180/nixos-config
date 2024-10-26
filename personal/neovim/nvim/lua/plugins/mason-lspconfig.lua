return {
  "williamboman/mason-lspconfig.nvim",
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = { "lua_ls", "clangd", "jdtls", "ts_ls", "rnix" },
    })
  end
}

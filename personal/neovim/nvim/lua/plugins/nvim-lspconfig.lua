-- mason lsp config utilizes mason to automatically ensure lsp servers you want installed are installed
return {
  "neovim/nvim-lspconfig",
  config = function()
    local capabilities = require('cmp_nvim_lsp').default_capabilities()

    local lspconfig = require("lspconfig")

    -- setting up the lua language server.
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
    })
    -- setting up the clangd (for C and C++) language server.
    lspconfig.clangd.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        client.server_capabilities.signatureHelpProvider = false
      end,
    })
    -- setting up the typescript language server
    lspconfig.tsserver.setup({
      capabilities = capabilities,
    })
    -- setting up the java typescript language server
    lspconfig.jdtls.setup({
      capabilities = capabilities,
    })
    -- setting up the nix language server
    lspconfig.rnix.setup({
      capabilities = capabilities,
    })


    -- keybinds
    -- shows the code documentation for the code that the cursor is over
    vim.keymap.set('n', '<leader>ch', vim.lsp.buf.hover, { desc = "[C]ode [H]over Documentation" })
    vim.keymap.set('n', '<leader>cd', vim.lsp.buf.definition, { desc = "[C]ode Goto [D]efinition" })
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { desc = "[C]ode [A]ctions" })
    vim.keymap.set({ 'n', 'v' }, '<leader>cr', vim.lsp.buf.rename, { desc = "[C]ode [R]ename" })
    vim.keymap.set('n', '<leader>cD', vim.lsp.buf.declaration, { desc = "[C]ode Goto [D]eclaration" })
  end
}

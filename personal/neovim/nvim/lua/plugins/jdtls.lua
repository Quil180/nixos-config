-- utility plugin for configuring the java language server for us
return {
  "mfussenegger/nvim-jdtls",
  ft = 'java',
  dependencies = {
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
  },

  config = function()
  end
}

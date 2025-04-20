{...}: {
  vim = {
    languages = {
      nix = {
        enable = true;
        format.enable = true;
      };
      clang = {
        # C/C++
        enable = true;
        dap.enable = true;
        lsp.enable = true;
        treesitter.enable = true;
        cHeader = true;
      };
      java = {
        enable = true;
        lsp.enable = false;
        treesitter.enable = true;
      };
      bash = {
        enable = true;
        format.enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
      python = {
        enable = true;
        format.enable = true;
        dap.enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
      rust = {
        enable = true;
        crates = {
          enable = true;
          codeActions = true;
        };
        format.enable = true;
        dap.enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
      lua = {
        enable = true;
        lsp.enable = true;
        treesitter.enable = true;
      };
    };
  };
}

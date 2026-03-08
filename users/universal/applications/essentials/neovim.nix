{
  pkgs,
  inputs,
  dotfilesDir,
  ...
}:
{
  programs.neovim = {
    # Enabling customization of neovim and nightly version
    enable = true;
    package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # setting neovim to be default editor and extra aliases
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home = {
    packages = with pkgs; [
      # Place all language servers here!!!!
      # Lua
      lua-language-server
      # Rust
      rust-analyzer
      # C/C++
      clang-tools
      # SystemVerilog
      verible
      # VHDL
      vhdl-ls
      # Python
      ruff
      basedpyright
      # Nix
      nixd
      # QML
      kdePackages.qtdeclarative # provides qmlls
      # For Latex
      texlab
      zathura

      # Git TUI
      lazygit

      # Formatters (LSPs often don't include formatters)
      nixfmt # Nix formatter
      stylua # Lua formatter
    ];
  };

  # Note: neovim config is in a git submodule, so we use absolute paths
  # to avoid Nix flake visibility issues with submodules
  xdg.configFile = {
    "nvim/lsp" = {
      source = neovim/lsp;
      force = true;
    };
    "nvim/init.lua" = {
      text = builtins.replaceStrings [ "~/.dotfiles" ] [ dotfilesDir ] (builtins.readFile ./neovim/init.lua);
      force = true;
    };
  };

  # Setup Avante.nvim and clean up any leftover backup files
  home.activation.setupNeovim = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    		# Remove any backup files that cause interactive prompts during home-manager switch
    		$DRY_RUN_CMD rm -f $HOME/.config/nvim/init.lua.backup || true

    		# Build avante.nvim if it exists (requires make, cargo, and openssl)
    		if [ -d "$HOME/.local/share/nvim/site/pack/core/opt/avante.nvim" ]; then
    			cd "$HOME/.local/share/nvim/site/pack/core/opt/avante.nvim"
    			PATH="${pkgs.rustc}/bin:${pkgs.cargo}/bin:${pkgs.gcc}/bin:${pkgs.perl}/bin:${pkgs.pkg-config}/bin:$PATH" \
    			OPENSSL_NO_VENDOR=1 \
    			PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig" \
    			OPENSSL_DIR="${pkgs.openssl.dev}" \
    			OPENSSL_LIB_DIR="${pkgs.openssl.out}/lib" \
    			OPENSSL_INCLUDE_DIR="${pkgs.openssl.dev}/include" \
    			$DRY_RUN_CMD ${pkgs.gnumake}/bin/make BUILD_FROM_SOURCE=true || true
    		fi
    	'';
}

{
	pkgs,
	inputs,
	username,
	dotfilesDir,
	...
}: {
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
      source = neovim/init.lua;
      force = true;
    };
	};

	# Create a wrapper script to patch the dotfiles path in init.lua at activation
	home.activation.patchNeovimConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
		$DRY_RUN_CMD sed -i 's|~/.dotfiles|${dotfilesDir}|g' $HOME/.config/nvim/init.lua || true
	'';
}

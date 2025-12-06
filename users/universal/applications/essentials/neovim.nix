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

			# For Latex
			zathura
		];
	};

	# Note: neovim config is in a git submodule, so we use absolute paths
	# to avoid Nix flake visibility issues with submodules
	xdg.configFile = {
		"nvim/lsp".source = /home/${username}/.dotfiles/users/universal/applications/essentials/neovim/lsp;
		"nvim/init.lua".source = /home/${username}/.dotfiles/users/universal/applications/essentials/neovim/init.lua;
	};

	# Create a wrapper script to patch the dotfiles path in init.lua at activation
	home.activation.patchNeovimConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary"] ''
		$DRY_RUN_CMD sed -i 's|~/.dotfiles|${dotfilesDir}|g' $HOME/.config/nvim/init.lua || true
	'';
}

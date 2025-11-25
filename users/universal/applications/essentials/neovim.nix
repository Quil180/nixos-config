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

	xdg.configFile = {
		"nvim/lsp".source = ./neovim/lsp;
		"nvim/init.lua".text = builtins.replaceStrings 
			["${dotfilesDir}"] 
			(builtins.readFile ./neovim/init.lua);
	};
}

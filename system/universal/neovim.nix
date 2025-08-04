{
	pkgs,
	inputs,
	...
}: {
	programs.neovim = {
		# Enabling customization of neovim and nightly version
		enable = true;
		package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

		# setting neovim to be default editor and extra aliases
		defaultEditor = true;
		viAlias = true;
		vimAlias = true;

		configure = {
			customRC = ''
				
			'';
		};
	};
}

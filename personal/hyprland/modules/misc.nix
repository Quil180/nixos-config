{pkgs, ...}:

{
# customizing foot with a different font
	programs.foot = {
		enable = true;
		settings = {
			main = {
				font = "iosevka-bold:size=10";
				dpi-aware = "yes";
			};

			mouse = {
				hide-when-typing = "yes";
			};
		};
	};

	programs.zoxide = {
		enable = true;
		enableZshIntegration = true;
	};

}

{pkgs, ...}:

{
  # customizing foot with a different font
	programs.foot = {
		enable = true;
		settings = {
			main = {
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

	services.network-manager-applet.enable = true;
}

{pkgs, config, ...}:

{
	  home.packages = (with pkgs; [
		dunst
		libnotify
	  ]);

	services.dunst = {
	    enable = true;
	    settings = {
	      global = {
		dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
		follow = "mouse";
		font = "iosevka 12";
		format = "<b>%s</b>\\n%b";
		frame_width = 2;
		geometry = "500x5-5+30";
		horizontal_padding = 8;
		icon_position = "off";
		line_height = 0;
		markup = "full";
		padding = 8;
		separator_height = 2;
		transparency = 10;
		word_wrap = true;
		
		# coloring
		frame_color = "#${config.colorScheme.palette.base05}";
		separator_color = "#${config.colorScheme.palette.base05}";
	      };
	      urgency_low = with config.colorScheme.palette; {
	          background = "#${base01}";
	          foreground = "#${base03}";
	      };
	      urgency_normal = with config.colorScheme.palette; {
	        background = "#${base02}";
	        foreground = "#${base05}";
	      };
	      urgency_critical = with config.colorScheme.palette; {
	        background = "#${base08}";
	        foreground = "#${base06}";
	        timeout = 0;
	      };

	      shortcuts = {
		context = "mod4+grave";
		close = "mod4+shift+space";
	      };
	    };
	  };
}

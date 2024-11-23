{pkgs, ...}:

{
	  home.packages = (with pkgs; [
		libnotify
	  ]);

	services.dunst = {
	    enable = true;
	    settings = {
	      global = {
		dmenu = "${pkgs.rofi}/bin/rofi -dmenu";
		follow = "mouse";
		font = "Droid Sans 10";
		format = "<b>%s</b>\\n%b";
		frame_color = "#555555";
		frame_width = 2;
		geometry = "500x5-5+30";
		horizontal_padding = 8;
		icon_position = "off";
		line_height = 0;
		markup = "full";
		padding = 8;
		separator_color = "frame";
		separator_height = 2;
		transparency = 10;
		word_wrap = true;
	      };

	      shortcuts = {
		context = "mod4+grave";
		close = "mod4+shift+space";
	      };
	    };
	  };
}

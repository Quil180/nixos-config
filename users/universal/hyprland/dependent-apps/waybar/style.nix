{config, ...}: {
  programs.waybar.style = with config.lib.stylix.colors.withHashtag; ''
    @define-color red       #cc241d;
    @define-color green     #98971a;
    @define-color yellow    #d79921;
    @define-color blue      #458588;
    @define-color purple    #b16286;
    @define-color aqua      #689d6a;
    @define-color gray      #a89984;
    @define-color brgray    #928374;
    @define-color brred     #fb4934;
    @define-color brgreen   #b8bb26;
    @define-color bryellow  #fabd2f;
    @define-color brblue    #83a598;
    @define-color brpurple  #d3869b;
    @define-color braqua    #8ec07c;
    @define-color orange    #d65d0e;
    @define-color brorange  #fe8019;

    * {
      border: none;
      font-size: 14px;
      border-radius: 5px;
    }

    window#waybar {
      background-color: transparent;
    }

    tooltip {
      font-family: Iosevka Nerd Font Propo, monospace;
      background-color: ${base02};
      border-radius: 5px;
      border: 1px solid ${base02};
    }

    tooltip label {
      color: ${base04};
      text-shadow: none;
    }

    .modules-right {
      margin: 10px 10px 0 0;
    }
    .modules-center {
      margin: 10px 0 0 0;
    }
    .modules-left {
      margin: 10px 0 0 10px;
    }

    #workspaces {
      background-color: ${base01};
    }

    #workspaces button {
      padding: 0 5px;
      color: ${base04};
      border-radius: 0;
    }

    #workspaces button:first-child {
      border-radius: 5px 0 0 5px;
    }

    #workspaces button:last-child {
      border-radius: 0 5px 5px 0;
    }

    #workspaces button:first-child:last-child {
      border-radius: 5px;
    }

    #workspaces button:hover {
      color: ${base04};
    }

    #workspaces button.focused {
      background-color: ${base0D};
    }

    #workspaces button.urgent {
      background-color: ${base08};
    }

    #idle_inhibitor,
    #cava,
    #scratchpad,
    #mode,
    #window,
    #clock,
    #battery,
    #backlight,
    #custom-weather,
    #wireplumber,
    #tray,
    #mpris,
    #load {
      padding: 0 10px;
      background-color: ${base01};
      color: ${base04};
    }

    #mode {
      background-color: @aqua;
      color: ${base01};
    }

    /* If workspaces is the leftmost module, omit left margin */
    .modules-left > widget:first-child > #workspaces {
      margin-left: 0;
    }

    /* If workspaces is the rightmost module, omit right margin */
    .modules-right > widget:last-child > #workspaces {
      margin-right: 0;
    }

    #cava {
      padding: 0 5px;
    }

    #battery.charging, #battery.plugged {
      background-color: @green;
      color: ${base01};
    }

    @keyframes blink {
      to {
        background-color: ${base01};
        color: ${base04};
      }
    }

    /* Using steps() instead of linear as a timing function to limit cpu usage */
    #battery.critical:not(.charging) {
      background-color: @red;
      color: ${base01};
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: steps(12);
      animation-iteration-count: infinite;
      animation-direction: alternate;
    }

    #wireplumber.muted {
      background-color: @red;
      color: ${base05};
    }

    #tray > .passive {
      -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
    }

    #mpris.playing {
      background-color: ${base01};
    }

    #tray menu {
      font-family: sans-serif;
    }

    #scratchpad.empty {
      background: transparent;
      padding: 0;
    }

    #cpu {
      background-color: ${base01};
    }

    #memory {
      background-color: ${base01};
    }

    #temperature {
      background-color: ${base01};
    }
  '';
}

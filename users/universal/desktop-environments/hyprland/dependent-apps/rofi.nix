_: {
  flake.homeModules.rofi =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      colors = config.lib.stylix.colors.withHashtag;
      rofi-cliphist = pkgs.writeShellScriptBin "rofi-cliphist" ''
        PATH="${
          lib.makeBinPath [
            pkgs.cliphist
            pkgs.wl-clipboard
            pkgs.rofi
            pkgs.python3
            pkgs.wtype
          ]
        }:$PATH"

        cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbnails"
        mkdir -p "$cache_dir"

        item=$(python3 -c '
        import sys, os, subprocess, re

        cache_dir = os.path.expanduser(sys.argv[1])
        pattern = re.compile(r"^\[\[ binary data [^\]]*\b(png|jpe?g|gif|webp|bmp|ico)\b[^\]]*\]\]$")

        existing = set(os.listdir(cache_dir)) if os.path.exists(cache_dir) else set()
        seen = set()

        proc = subprocess.Popen(["cliphist", "list"], stdout=subprocess.PIPE, text=True, errors="replace")
        for line in proc.stdout:
            line = line.rstrip("\n")
            parts = line.split("\t", 1)
            if len(parts) == 2:
                cid, text = parts
                m = pattern.match(text)
                if m:
                    ext = m.group(1)
                    filename = cid + "." + ext
                    seen.add(filename)
                    img_path = os.path.join(cache_dir, filename)
                    if not os.path.exists(img_path):
                        with open(img_path, "wb") as f:
                            subprocess.run(["cliphist", "decode", cid], stdout=f, check=False)
                    sys.stdout.write(line + "\0icon\x1f" + img_path + "\n")
                    continue
            sys.stdout.write(line + "\n")

        for old_file in (existing - seen):
            try:
                os.remove(os.path.join(cache_dir, old_file))
            except OSError:
                pass
        ' "$cache_dir" | rofi -dmenu -show-icons -p "Clipboard" -theme-str "element-icon { size: 1.4em; vertical-align: 0.5; } element-text { vertical-align: 0.5; }") || exit 0

        if [ -n "$item" ]; then
          printf '%s\n' "$item" | cliphist decode | wl-copy
          sleep 0.1
          wtype -k XF86Paste
        fi
      '';
    in
    {
      stylix.targets.rofi.enable = false;

      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        theme = "spotlight";
        extraConfig = {
          modi = "drun,run,filebrowser";
          show-icons = true;
          icon-theme = "Papirus-Dark";
          display-drun = "󰍉 ";
          display-run = " ";
          display-filebrowser = " ";
          display-window = " ";
          drun-display-format = "{name}";
          window-format = "{w} · {c} · {t}";
        };
      };

      xdg.configFile."rofi/spotlight.rasi".text = ''
        * {
            font: "Iosevka Nerd Font 11";
            background-color: transparent;
            text-color: ${colors.base05};
        }

        window {
            transparency: "real";
            location: center;
            anchor: center;
            fullscreen: false;
            width: 650px;
            x-offset: 0px;
            y-offset: 0px;
            enabled: true;
            margin: 0px;
            padding: 24px;
            border: 2px solid;
            border-radius: 16px;
            border-color: ${colors.base0D}66;
            background-color: ${colors.base00}D9;
            cursor: "default";
        }

        mainbox {
            enabled: true;
            spacing: 16px;
            margin: 0px;
            padding: 0px;
            border: 0px;
            background-color: transparent;
            children: [ "inputbar", "listview" ];
        }

        inputbar {
            enabled: true;
            spacing: 12px;
            margin: 0px;
            padding: 12px 16px;
            border: 1px solid;
            border-radius: 12px;
            border-color: ${colors.base02}66;
            background-color: ${colors.base01}66;
            text-color: ${colors.base05};
            children: [ "prompt", "entry" ];
        }

        prompt {
            enabled: true;
            background-color: transparent;
            text-color: ${colors.base0D};
            font: "Iosevka Nerd Font 12";
            vertical-align: 0.5;
        }

        entry {
            enabled: true;
            background-color: transparent;
            text-color: ${colors.base05};
            cursor: text;
            placeholder: "Search...";
            placeholder-color: ${colors.base03}99;
            vertical-align: 0.5;
        }

        listview {
            enabled: true;
            columns: 1;
            lines: 8;
            cycle: true;
            dynamic: true;
            scrollbar: false;
            layout: vertical;
            reverse: false;
            fixed-height: false;
            fixed-columns: true;
            spacing: 6px;
            margin: 0px;
            padding: 0px;
            border: 0px;
            background-color: transparent;
            cursor: "default";
        }

        element {
            enabled: true;
            spacing: 14px;
            margin: 0px;
            padding: 10px 14px;
            border: 1px solid;
            border-color: transparent;
            border-radius: 10px;
            background-color: transparent;
            text-color: ${colors.base05};
            cursor: pointer;
        }

        element normal.normal, element alternate.normal {
            background-color: transparent;
            text-color: ${colors.base05};
        }

        element normal.urgent, element alternate.urgent {
            background-color: transparent;
            text-color: ${colors.base08};
        }

        element normal.active, element alternate.active {
            background-color: transparent;
            text-color: ${colors.base0D};
        }

        element selected.normal {
            background-color: ${colors.base02}66;
            border-color: ${colors.base0D}80;
            text-color: ${colors.base06};
        }

        element selected.urgent {
            background-color: ${colors.base08}40;
            border-color: ${colors.base08}80;
            text-color: ${colors.base06};
        }

        element selected.active {
            background-color: ${colors.base0D}33;
            border-color: ${colors.base0D}80;
            text-color: ${colors.base06};
        }

        element-icon {
            background-color: transparent;
            text-color: inherit;
            size: 28px;
            cursor: inherit;
            vertical-align: 0.5;
        }

        element-text {
            background-color: transparent;
            text-color: inherit;
            highlight: inherit;
            cursor: inherit;
            vertical-align: 0.5;
            horizontal-align: 0.0;
        }

        message {
            enabled: true;
            margin: 0px;
            padding: 12px 16px;
            border: 1px solid;
            border-radius: 10px;
            border-color: ${colors.base02}66;
            background-color: ${colors.base01}66;
            text-color: ${colors.base05};
        }

        textbox {
            background-color: transparent;
            text-color: ${colors.base05};
            vertical-align: 0.5;
            horizontal-align: 0.0;
            highlight: none;
        }

        error-message {
            padding: 16px;
            border: 2px solid;
            border-radius: 12px;
            border-color: ${colors.base08};
            background-color: ${colors.base00};
            text-color: ${colors.base05};
        }
      '';

      home.packages = [
        rofi-cliphist
        pkgs.papirus-icon-theme
      ];
    };
}

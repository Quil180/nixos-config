_: {
  flake.homeModules.rofi =
    { pkgs, lib, ... }:
    let
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
        ' "$cache_dir" | rofi -dmenu -show-icons -p "Clipboard" -theme-str "element-icon { size: 1.2em; vertical-align: 0.5; } element-text { vertical-align: 0.5; }") || exit 0

        if [ -n "$item" ]; then
          printf '%s\n' "$item" | cliphist decode | wl-copy
          sleep 0.1
          wtype -k XF86Paste
        fi
      '';
    in
    {
      programs.rofi = {
        enable = true;
      };

      home.packages = [ rofi-cliphist ];
    };
}

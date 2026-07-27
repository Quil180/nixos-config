import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property string currentWallpaper: ""
    property var wallpapers: []
    property var readyThumbnails: ({})
    property bool loading: true

    signal wallpaperChanged(string path)
    signal thumbnailsUpdated()

    function refreshWallpapers() {
        console.log("[WallpaperWidget] refreshWallpapers() called");
        scanProcess.outputBuffer = "";
        scanProcess.running = true;
    }

    function getThumbnailPath(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath.length === 0) return "";
        var idx = wallpaperPath.lastIndexOf('/');
        if (idx === -1) return wallpaperPath;
        var filename = wallpaperPath.substring(idx + 1);
        var stem = filename.replace(/\.[^/.]+$/, "");
        var thumbName = stem + ".jpg";
        if (root.readyThumbnails && root.readyThumbnails[thumbName]) {
            var parts = wallpaperPath.split('/');
            var homeDir = (parts.length > 2 && parts[1] === "home") ? ("/" + parts[1] + "/" + parts[2]) : "";
            if (homeDir.length > 0) {
                return homeDir + "/.cache/quickshell/thumbnails/" + thumbName;
            }
        }
        return wallpaperPath;
    }

    function setWallpaper(path) {
        if (path && path.length > 0) {
            root.currentWallpaper = path;
            saveProcess.targetPath = path;
            saveProcess.running = true;
            applyWaybarProcess.targetPath = path;
            applyWaybarProcess.running = true;
            root.wallpaperChanged(path);
        }
    }

    function setRandomWallpaper() {
        if (root.wallpapers.length > 0) {
            var available = root.wallpapers.filter(w => w !== root.currentWallpaper);
            if (available.length === 0) available = root.wallpapers;
            var randomIndex = Math.floor(Math.random() * available.length);
            setWallpaper(available[randomIndex]);
        }
    }

    // Restore current wallpaper path on startup
    Process {
        id: restoreProcess
        command: ["bash", "-c", "cat \"$HOME/.config/quickshell/current_wallpaper\" 2>/dev/null || echo ''"]

        stdout: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] restoreProcess stdout:", data);
                var path = data.trim();
                if (path.length > 0) {
                    root.currentWallpaper = path;
                }
            }
        }

        onExited: (code, status) => {
            console.log("[WallpaperWidget] restoreProcess exited, code:", code, "status:", status);
            refreshWallpapers();
        }

        Component.onCompleted: {
            console.log("[WallpaperWidget] restoreProcess starting");
            running = true;
        }
    }

    // Scan wallpapers directory
    Process {
        id: scanProcess
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; find -L \"$HOME/.dotfiles/wallpapers\" -maxdepth 1 -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \\) | sort"]

        property string outputBuffer: ""

        onRunningChanged: {
            console.log("[WallpaperWidget] scanProcess running changed to:", running);
            if (running) {
                console.log("[WallpaperWidget] scanProcess command:", JSON.stringify(command));
            }
        }

        stdout: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] scanProcess stdout line:", data);
                scanProcess.outputBuffer += data + "\n";
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] scanProcess STDERR:", data);
            }
        }

        onExited: (code, status) => {
            console.log("[WallpaperWidget] scanProcess exited, code:", code, "status:", status);
            console.log("[WallpaperWidget] scanProcess outputBuffer length:", scanProcess.outputBuffer.length);
            console.log("[WallpaperWidget] scanProcess raw outputBuffer:", scanProcess.outputBuffer.substring(0, 500));
            var lines = scanProcess.outputBuffer.split("\n");
            var results = [];
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.length > 0) {
                    results.push(line);
                }
            }
            console.log("[WallpaperWidget] Found", results.length, "wallpapers");
            if (results.length > 0) {
                console.log("[WallpaperWidget] First wallpaper:", results[0]);
                console.log("[WallpaperWidget] Last wallpaper:", results[results.length - 1]);
            }
            // Assign a fresh array copy to ensure QML detects the change
            root.wallpapers = results.slice();
            root.loading = false;
            scanProcess.outputBuffer = "";
            console.log("[WallpaperWidget] root.wallpapers.length is now:", root.wallpapers.length);

            if (!root.currentWallpaper || root.wallpapers.indexOf(root.currentWallpaper) === -1) {
                if (root.wallpapers.length > 0) {
                    var defaultWp = root.wallpapers.find(w => w.endsWith("wallpaper.jpg"));
                    root.setWallpaper(defaultWp ? defaultWp : root.wallpapers[0]);
                }
            } else {
                applyWaybarProcess.targetPath = root.currentWallpaper;
                applyWaybarProcess.running = true;
            }

            // Start pre-generating cached thumbnails and waybar stylix definitions in background
            scanThumbnailsProcess.running = true;
            thumbnailProcess.running = true;
            waybarCacheProcess.running = true;
        }
    }

    // Scan existing generated thumbnails in cache
    Process {
        id: scanThumbnailsProcess
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; mkdir -p \"$HOME/.cache/quickshell/thumbnails\" && ls -1 \"$HOME/.cache/quickshell/thumbnails\" 2>/dev/null"]

        property string outputBuffer: ""

        onRunningChanged: {
            if (running) {
                outputBuffer = "";
            }
        }

        stdout: SplitParser {
            onRead: data => {
                scanThumbnailsProcess.outputBuffer += data + "\n";
            }
        }

        onExited: (code, status) => {
            var lines = scanThumbnailsProcess.outputBuffer.split("\n");
            var map = {};
            for (var i = 0; i < lines.length; i++) {
                var name = lines[i].trim();
                if (name.length > 0) {
                    map[name] = true;
                }
            }
            root.readyThumbnails = map;
            scanThumbnailsProcess.outputBuffer = "";
            console.log("[WallpaperWidget] readyThumbnails count:", Object.keys(map).length);
            root.thumbnailsUpdated();
        }
    }

    // Pre-generate cached wallpaper thumbnails
    Process {
        id: thumbnailProcess
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; mkdir -p \"$HOME/.cache/quickshell/thumbnails\" && rm -f \"$HOME/.cache/quickshell/thumbnails/\"*.*.jpg 2>/dev/null; if command -v python3 >/dev/null 2>&1; then python3 \"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\" --thumbnails; else nix-shell -p python3Packages.pillow --run \"python3 \\\"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\\\" --thumbnails\"; fi"]

        stdout: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] thumbnailProcess:", data);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] thumbnailProcess STDERR:", data);
            }
        }

        onExited: (code, status) => {
            console.log("[WallpaperWidget] thumbnailProcess exited, code:", code, "status:", status);
            scanThumbnailsProcess.running = true;
        }
    }

    // Pre-generate cached Waybar Stylix CSS for all wallpapers
    Process {
        id: waybarCacheProcess
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; if command -v python3 >/dev/null 2>&1; then python3 \"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\" --cache-all; else nix-shell -p python3Packages.pillow --run \"python3 \\\"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\\\" --cache-all\"; fi"]

        stdout: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] waybarCacheProcess:", data);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] waybarCacheProcess STDERR:", data);
            }
        }

        onExited: (code, status) => {
            console.log("[WallpaperWidget] waybarCacheProcess exited, code:", code, "status:", status);
        }
    }

    // Apply Waybar Stylix CSS for selected wallpaper and signal Waybar
    Process {
        id: applyWaybarProcess
        property string targetPath: ""
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; if command -v python3 >/dev/null 2>&1; then python3 \"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\" --apply \"$1\"; else nix-shell -p python3Packages.pillow --run \"python3 \\\"$HOME/.dotfiles/users/universal/desktop-environments/bars/waybar/generate_waybar_stylix.py\\\" --apply \\\"$1\\\"\"; fi", "sh", targetPath]

        stdout: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] applyWaybarProcess:", data);
                var trimmed = data.trim();
                if (trimmed.startsWith("PALETTE_JSON:")) {
                    try {
                        var jsonStr = trimmed.substring(13);
                        var palette = JSON.parse(jsonStr);
                        console.log("[WallpaperWidget] Updating Theme colors for wallpaper:", applyWaybarProcess.targetPath);
                        Theme.updateColors(palette);
                    } catch (e) {
                        console.log("[WallpaperWidget] Error parsing PALETTE_JSON:", e);
                    }
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.log("[WallpaperWidget] applyWaybarProcess STDERR:", data);
            }
        }

        onExited: (code, status) => {
            console.log("[WallpaperWidget] applyWaybarProcess exited, code:", code, "status:", status);
        }
    }

    // Save selected wallpaper path
    Process {
        id: saveProcess
        property string targetPath: ""
        command: ["bash", "-c", "export PATH=\"$PATH:/run/current-system/sw/bin:/etc/profiles/per-user/$USER/bin:/etc/profiles/per-user/quil/bin:$HOME/.nix-profile/bin:$HOME/.local/state/nix/profiles/home-manager/home-path/bin:$HOME/.local/state/nix/profiles/profile/bin:/nix/var/nix/profiles/default/bin\"; mkdir -p \"$HOME/.config/quickshell\" && printf '%s' \"$1\" > \"$HOME/.config/quickshell/current_wallpaper\"", "sh", targetPath]
    }
}

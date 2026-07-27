{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.startup =
    { pkgs, ... }:
    let
      dotfiles = "~/.dotfiles";
    in
    {
      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("awww-daemon")
                hl.exec_cmd("awwww img ${dotfiles}/wallpapers/wallpaper.jpg")
                hl.exec_cmd("nm-applet --indicator")
                hl.exec_cmd("wl-paste --watch cliphist store")
                hl.exec_cmd("xwaylandvideobridge")
                hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP --all")
                hl.exec_cmd("systemctl --user enable --now hyprpolkitagent.service")
                hl.exec_cmd("hyprctl setcursor rose-pine-hyprcursor 24")
                hl.exec_cmd("quickshell -p ~/.config/quickshell/bar.qml")
                hl.exec_cmd("rog-control-center")
                hl.exec_cmd("[workspace 1 silent] discord --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland")
                hl.exec_cmd("[workspace 2 silent] firefox --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland")
              end'')
          ];
        }
      ];
    };
}

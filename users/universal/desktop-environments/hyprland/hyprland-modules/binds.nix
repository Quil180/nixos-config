{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.binds = { ... }: {
    wayland.windowManager.hyprland.extraConfig = ''
      -- Variables
      local mod = "SUPER"
      local term = "foot"
      local browser = "firefox"
      local file = "ranger"

      -- Mouse Binds (Move & Resize windows)
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Basic Keybinds
      hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(term))
      hl.bind(mod .. " + Q", hl.dsp.window.kill())
      hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + R", hl.dsp.exec_cmd("rofi -show drun"))
      hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pseudo())
      hl.bind(mod .. " + J", hl.dsp.layout("togglesplit"))
      hl.bind(mod .. " + SHIFT + L", hl.dsp.exit())
      hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())

      -- Binds to Launch Apps
      hl.bind(mod .. " + E", hl.dsp.exec_cmd(term .. " -e " .. file))
      hl.bind(mod .. " + W", hl.dsp.exec_cmd(browser .. " --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland"))
      hl.bind(mod .. " + D", hl.dsp.exec_cmd("discord --enable-features=WaylandWindowDecorations --ozone-platform-hint=wayland"))
      hl.bind(mod .. " + G", hl.dsp.exec_cmd("steam"))
      hl.bind(mod .. " + SHIFT + G", hl.dsp.exec_cmd("lutris"))
      hl.bind(mod .. " + O", hl.dsp.exec_cmd("obs QT_QPA_PLATFORM=wayland"))
      hl.bind(mod .. " + H", hl.dsp.exec_cmd(term .. " -e btop"))
      hl.bind(mod .. " + I", hl.dsp.exec_cmd("gimp"))
      hl.bind(mod .. " + M", hl.dsp.exec_cmd("foot spotify_player"))
      hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("rog-control-center"))
      hl.bind(mod .. " + ALT + R", hl.dsp.exec_cmd("polychromatic-controller"))
      hl.bind(mod .. " + V", hl.dsp.exec_cmd(term .. " --hold vivado && notify-send 'Vivado was Started'"))

      -- Screenshot Keybinds
      hl.bind(mod .. " + ALT + P", hl.dsp.exec_cmd("grimblast copy area && notify-send 'Zone Copied'"))
      hl.bind(mod .. " + P", hl.dsp.exec_cmd("grimblast copy output && notify-send 'Current Screen Copied'"))
      hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("grimblast screen output && notify-send 'All Screens Copied'"))

      -- Volume Control Binds
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))

      -- Brightness Control Binds
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +20%"))
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 20%-"))

      -- Selecting Monitor Focus / Workspace navigation
      hl.bind(mod .. " + M", hl.dsp.submap("moniter_select"))
      hl.bind(mod .. " + SHIFT + Up", hl.dsp.focus({ workspace = "r+1" }))
      hl.bind(mod .. " + SHIFT + Down", hl.dsp.focus({ workspace = "r-1" }))
      hl.bind(mod .. " + ALT + Up", hl.dsp.window.move({ workspace = "emptym" }))
      hl.bind(mod .. " + ALT + Down", hl.dsp.window.move({ workspace = "empty", silent = true }))

      -- Workspace Alt-Tab
      hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "previous_per_monitor" }))

      -- Workspaces 1..10 (Switching, Moving with focus, Moving silently)
      for i = 1, 10 do
        local key = tostring(i % 10)
        local target = "r~" .. i
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = target }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = target }))
        hl.bind(mod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = target, silent = true }))
      end

      -- Special Workspace (Scratchpad)
      hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      -- Move Focus with Arrow Keys
      hl.bind(mod .. " + Left", hl.dsp.focus({ direction = "left" }))
      hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "right" }))
      hl.bind(mod .. " + Up", hl.dsp.focus({ direction = "up" }))
      hl.bind(mod .. " + Down", hl.dsp.focus({ direction = "down" }))

      -- Moving Windows with Arrow Keys
      hl.bind(mod .. " + SHIFT + Left", hl.dsp.window.swap({ direction = "left" }))
      hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.swap({ direction = "right" }))
      hl.bind(mod .. " + SHIFT + Up", hl.dsp.window.swap({ direction = "up" }))
      hl.bind(mod .. " + SHIFT + Down", hl.dsp.window.swap({ direction = "down" }))

      -- Resizing Windows with Arrow Keys
      hl.bind(mod .. " + CTRL + Left", hl.dsp.window.resize({ x = -60, y = 0, relative = true }))
      hl.bind(mod .. " + CTRL + Right", hl.dsp.window.resize({ x = 60, y = 0, relative = true }))
      hl.bind(mod .. " + CTRL + Down", hl.dsp.window.resize({ x = 0, y = 60, relative = true }))
      hl.bind(mod .. " + CTRL + Up", hl.dsp.window.resize({ x = 0, y = -60, relative = true }))
    '';
  };
}

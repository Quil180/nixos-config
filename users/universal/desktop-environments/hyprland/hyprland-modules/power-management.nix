{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.power-management =
    { pkgs, ... }:
    let
      power-monitor = pkgs.writeShellScriptBin "power-monitor" ''
        # Function to apply power saving settings
        apply_battery_settings() {
          echo "Applying battery settings..."
          # Set refresh rate to 60Hz
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,2560x1600@60,0x0,1.25"
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-2,2560x1600@60,0x0,1.25"
          # Set brightness to 50%
          ${pkgs.brightnessctl}/bin/brightnessctl s 50%
          # Disable Hyprland eye-candy
          ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled false
          ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled false
          ${pkgs.hyprland}/bin/hyprctl keyword animations:enabled false
          # Set Asus profile to Quiet and dim keyboard
          ${pkgs.asusctl}/bin/asusctl profile set Quiet
          ${pkgs.asusctl}/bin/asusctl leds set off
        }

        # Function to apply AC settings
        apply_ac_settings() {
          echo "Applying AC settings..."
          # Set refresh rate back to 120Hz
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1,2560x1600@120,0x0,1.25"
          ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-2,2560x1600@120,0x0,1.25"
          # Enable Hyprland eye-candy
          ${pkgs.hyprland}/bin/hyprctl keyword decoration:blur:enabled true
          ${pkgs.hyprland}/bin/hyprctl keyword decoration:shadow:enabled true
          ${pkgs.hyprland}/bin/hyprctl keyword animations:enabled true
          # Set Asus profile to Balanced and restore keyboard
          ${pkgs.asusctl}/bin/asusctl profile set Balanced
          ${pkgs.asusctl}/bin/asusctl leds set med
        }

        # Initial check
        if [[ $(cat /sys/class/power_supply/AC0/online) -eq 0 ]]; then
          apply_battery_settings
        else
          apply_ac_settings
        fi

        # Monitor for changes via upower
        ${pkgs.upower}/bin/upower --monitor-detail | while read -r line; do
          if echo "$line" | grep -q "online:.*no"; then
            apply_battery_settings
          elif echo "$line" | grep -q "online:.*yes"; then
            apply_ac_settings
          fi
        done
      '';
    in
    {
      home.packages = [ power-monitor ];

      wayland.windowManager.hyprland.settings.on = [
        {
          _args = [
            "hyprland.start"
            (lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("${power-monitor}/bin/power-monitor")
              end'')
          ];
        }
      ];
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = 330;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };

    };
}

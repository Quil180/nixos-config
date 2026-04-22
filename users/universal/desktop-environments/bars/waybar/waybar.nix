{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.waybar = 
{pkgs, ...}: {
  home.packages = with pkgs; [
    waybar
  ];

  imports = [ topConfig.flake.homeModules.style ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 4;
        output = [
          "eDP-2"
          "eDP-1"
        ];

        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "hyprland/window"
        ];
        modules-right = [
          "idle_inhibitor"
          "cpu"
          "memory"
          "temperature"
          "wireplumber"
          "backlight"
          "clock"
          "battery"
          "tray"
        ];
        "hyprland/workspace" = {
          all-outputs = false;
          warp-on-scoll = false;
          enable-bar-scroll = true;
          disable-scroll-wraparound = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };
        "hyprland/window" = {
          format = "{title}";
          max-length = 40;
          all-outputs = true;
        };
        "tray" = {
          icon-size = 14;
          spacing = 10;
        };
        "clock" = {
          format = "{:%I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        "cpu" = {
          format = " {usage}%  ";
          tooltip = true;
        };
        "memory" = {
          format = " {}%  ";
        };
        "temperature" = {
          critical-threshold = 80;
          format = " {temperatureC}°C {icon} ";
          format-icons = [
            ""
          ];
        };
        "backlight" = {
          scroll-step = 5;
          format = "{icon} {percent}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
            ""
          ];
        };
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-full = "{icon}  {capacity}%";
          format-charging = "⏚  {capacity}%";
          format-plugged = "  {capacity}%";
          format-alt = "{icon}  {time}";
          format-good = "";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };
        "wireplumber" = {
          scroll-step = 5;
          format = "{icon}  {volume}%";
          format-bluetooth = "{icon}  {volume}% ";
          format-bluetooth-muted = " {icon}";
          format-muted = "";
          format-icons = {
            "headphone" = "";
            "hands-free" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [
              ""
              ""
              "󰕾"
              "󰕾"
              "󰕾"
              ""
              ""
              ""
            ];
          };
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };
      };
      otherBar = {
        layer = "top";
        position = "top";
        spacing = 4;
        output = [
          "HDMI-A-1"
          "DP-3"
        ];

        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "hyprland/window"
        ];

        "hyprland/workspace" = {
          all-outputs = true;
          warp-on-scoll = false;
          enable-bar-scroll = true;
          disable-scroll-wraparound = true;
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };
        "hyprland/window" = {
          format = "{title}";
          max-length = 40;
          all-outputs = true;
        };
        "tray" = {
          icon-size = 14;
          spacing = 10;
        };
        "clock" = {
          format = "{:%I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
      };
    };
  };
}
;
}

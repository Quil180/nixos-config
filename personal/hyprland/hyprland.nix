{ pkgs, ... }:

{

  # importing configs for waybar, foot, and wlogout, and rofi
  imports = [
    ./waybar.nix
  ];

  home.packages = (with pkgs; [
    # bare essentials
    #hyprland-protocols
    wl-clipboard
    sddm
    foot
    grim
    slurp
    xdg-utils
    #xdg-desktop-portal-hyprland
    pavucontrol
    rofi
    wlogout
    qt6.qtwayland
    qt5.qtwayland

  ]);

  wayland.windowManager.hyprland = {
    enable = true;
    settings = { };
    xwayland = {
      enable = true;
    };
    settings = {
      # setting the mod key
      "$mod" = "SUPER";
      # common aliases
      "$term" = "foot";
      "$browser" = "firefox";
      "$file" = "ranger";

      #actual keybindings
      bindm = [
        "$mod, RETURN, exec, foot"
        "$mod, Q, killactive,"
        "$mod, F, togglefloating,"
        "$mod, R, exec, rofi -show drun"
        "$mod SHIFT, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, L, exec, wlogout"
        "$mod SHIFT, F, fullscreen,0"

        # binds to launch apps
        "$mod, E, exec, $term -e $file"
        "$mod, W, exec, $browser"
        "$mod, D, exec, vesktop --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WebRTCPipeWireCapturer"
        "$mod, G, exec, steam"
        "$mod SHIFT, G, exec, lutris"
        "$mod, O, exec, obs QT_QPA_PLATFORM=wayland"
        "$mod, H, exec, foot -e btop"
        "$mod, I, exec, gimp"
        "$mod, M, exec, spotify-launcher"
        "$mod SHIFT, R, exec, polychromatic-controller"
      ];
    };
    # systemd.enable = true;
  };


  # customizing foot with a different font
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "iosevka-bold:size=10";
        dpi-aware = "yes";
      };

      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

  services.xserver.displayManager.sddm.enable = true;
}

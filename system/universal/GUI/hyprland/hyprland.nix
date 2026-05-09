{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.hyprland =
    { pkgs, inputs, ... }:
    {
      fonts.packages = with pkgs; [
        iosevka
      ];

      programs.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
        xwayland = {
          enable = true;
        };
      };

      security.polkit.enable = true;
      environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        NIXOS_OZONE_WL = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        AQ_NO_HARDWARE_CURSORS = "1";
        AQ_DRM_DEVICES = "/dev/dri/card2:/dev/dri/card2";
        MOZ_ENABLE_WAYLAND = "1";
        SDL_VIDEODRIVER = "wayland";
        PROTON_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11";
      };

      # enabling xdg
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = false;
        config = {
          common = {
            default = [ "gtk" ];
            "org.freedesktop.portal.OpenURI" = [ "gtk" ];
          };
          hyprland = {
            default = [
              "gtk"
              "hyprland"
            ];
            "org.freedesktop.portal.OpenURI" = [ "gtk" ];
          };
        };
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
      };

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    };
}

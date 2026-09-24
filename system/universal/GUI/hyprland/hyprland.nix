_: {
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
      # Only system-level vars NOT duplicated in the home module's
      # hyprland settings.env (ELECTRON_OZONE_PLATFORM_HINT, MOZ_ENABLE_WAYLAND,
      # AQ_DRM_DEVICES, WLR/AQ_NO_HARDWARE_CURSORS are owned by home-manager).
      environment.sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        NIXOS_OZONE_WL = "1";
        SDL_VIDEODRIVER = "wayland";
        PROTON_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        GDK_BACKEND = "wayland,x11";
      };

      # xdg.portal is configured in the home module (identical values) —
      # keeping it here would fight home-manager for ownership.

      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    };
}

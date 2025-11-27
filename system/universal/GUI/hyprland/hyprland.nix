{pkgs, ...}: {
  fonts.packages = with pkgs; [
    iosevka
  ];

  programs.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
    # withUWSM = true;
  };

  security.polkit.enable = true;
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "hyprland";
		ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # enabling xdg
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.portal.OpenURI" = ["gtk"];
      };
      hyprland = {
        default = ["gtk" "hyprland"];
        "org.freedesktop.portal.OpenURI" = ["gtk"];
      };
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };
}

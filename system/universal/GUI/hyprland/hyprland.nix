{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kdePackages.sddm
  ];

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

  services = {
    # setting sddm as default login screen
    displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      autoNumlock = true;
    };
    # for any applications that require native X11
    xserver.enable = true;
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

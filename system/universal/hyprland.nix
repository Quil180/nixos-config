{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    sddm
  ];

  fonts.packages = with pkgs; [
    iosevka
  ];

  programs.hyprland = {
    enable = true;
    xwayland = {
      enable = true;
    };
    withUWSM = true;
  };

  services = {
    xserver.enable = true;

    # setting sddm as default login screen
    displayManager.sddm = {
      enable = true;
      enableHidpi = true;
      autoNumlock = true;
    };
  };
  security.polkit.enable = true;
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    NIXOS_OZONE_WL = "1";
  };
}

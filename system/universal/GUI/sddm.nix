{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    kdePackages.sddm
  ];

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
}

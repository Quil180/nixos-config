{pkgs, ...}: {
  services = {
    # setting ly as default login screen
    displayManager.ly = {
      enable = true;
    };
    # for any applications that require native X11
    xserver.enable = true;
  };
}

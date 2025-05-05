{pkgs, ...}: {
  services.xserver.windowManager.dwm = {
    enable = true;
  };

  home.packages = with pkgs; [
    dmenu
    st
  ];
}

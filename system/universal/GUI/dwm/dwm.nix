{pkgs, ...}: {
  services.xserver = {
    enable = true;
    windowManager.dwm = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    dmenu
    st
  ];
}

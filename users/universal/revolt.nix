{pkgs, ...}: {
  home.packages = with pkgs; [
    revolt-desktop
  ];
}

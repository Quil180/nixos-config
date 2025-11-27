{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    realvnc-vnc-viewer
  ];
}

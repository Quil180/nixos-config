_: {
  flake.nixosModules.vncviewer =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        realvnc-vnc-viewer
      ];
    };
}

{inputs, pkgs, system, ...}:
{
  environment.systemPackages = [
    inputs.winboat.packages.${system}.winboat
    pkgs.freerdp
  ];
}

{pkgs, ...}:
{
  home.package = with pkgs; [
    verilator
  ];
}

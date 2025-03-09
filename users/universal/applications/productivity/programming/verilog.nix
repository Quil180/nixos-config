{pkgs, ...}:
{
  home.packages = with pkgs; [
    verilator # simulation
    gnumake # for verilator
    gcc # for verilator
    gtkwave # waveform visualizer
  ];
}

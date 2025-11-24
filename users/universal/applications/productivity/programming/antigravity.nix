{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # antigravity
    google-chrome
    # If you encounter issues with extensions or binaries, 
    # you can try the FHS version instead:
    antigravity-fhs
  ];
}

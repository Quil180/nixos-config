{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    haguichi
    logmein-hamachi
  ];
  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;
}

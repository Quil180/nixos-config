{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    haguichi
    logmein-hamachi
    bind.dnsutils
  ];
  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;
}

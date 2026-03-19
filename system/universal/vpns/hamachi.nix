{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bind.dnsutils
  ];

  programs.haguichi.enable = true;
  networking.firewall.trustedInterfaces = [ "ham0" ];
}

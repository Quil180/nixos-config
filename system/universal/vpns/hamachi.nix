_: {
  flake.nixosModules.hamachi =
    { pkgs, ... }:
    {
      # Hamachi's identity and network memberships.
      persist.directories = [ "/var/lib/logmein-hamachi" ];

      environment.systemPackages = with pkgs; [
        bind.dnsutils
      ];

      programs.haguichi.enable = true;
      networking.firewall.trustedInterfaces = [ "ham0" ];
    };
}

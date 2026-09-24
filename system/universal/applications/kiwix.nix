_: {
  flake.nixosModules.kiwix =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        kiwix
        kiwix-tools
      ];
    };
}

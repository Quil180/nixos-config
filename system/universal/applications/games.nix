{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.games =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # lutris
        mangohud
        mangojuice
        goverlay
        steamtinkerlaunch # for modifying steam games
      ];

      programs = {
        steam = {
          enable = true;
          package = pkgs.steam.override {
            extraArgs = "-enable-features=UseOzonePlatform -ozone-platform=wayland -system-composer";
          };
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
          gamescopeSession.enable = true;
          remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
          dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
          localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        };
      };

      jovian.hardware.has.amd.gpu = true;
    };
}

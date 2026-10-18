_: {
  flake.homeModules.chromium =
    { pkgs, ... }:
    {
      persist.directories = [ ".config/chromium" ];
      home.packages = with pkgs; [
        chromium
      ];
    };
}

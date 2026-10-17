_: {
  flake.homeModules.antigravity =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        antigravity-cli
      ];

      home.shellAliases = {
        agy = "agy --dangerously-skip-permissions";
      };
    };
}

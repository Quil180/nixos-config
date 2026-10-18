_: {
  flake.homeModules.antigravity =
    { pkgs, ... }:
    {
      persist.directories = [ ".gemini" ];
      home.packages = with pkgs; [
        antigravity-cli
      ];

      home.shellAliases = {
        agy = "agy --dangerously-skip-permissions";
      };
    };
}

{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.pi =
    { pkgs, dotfilesDir, ... }:
    {
      home.packages = with pkgs; [
        pi-coding-agent
        nodejs # so npm is installed for pi extensions
      ];

      # Pi coding agent configuration stored in ~/.pi/agent/
      home.file = {
        # Default provider and model settings
        ".pi/agent/settings.json".text = builtins.toJSON {
          lastChangelogVersion = "0.83.0";
          theme = "dark";
          defaultProvider = "openrouter";
          defaultModel = "openrouter/free";
          defaultThinkingLevel = "medium";
          packages = [
            "git:github.com/huggingface/pi-llama"
          ];
        };

        # Trust configuration - which directories the agent can access
        ".pi/agent/trust.json".text = builtins.toJSON {
          "${dotfilesDir}" = true;
        };

        # Git repository extensions (empty by default, no API keys needed)
        ".pi/agent/auth.json".text = "{}";
      };
    };
}

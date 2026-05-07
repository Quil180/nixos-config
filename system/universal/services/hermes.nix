{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.hermes =
    {
      pkgs,
      config,
      lib,
      inputs,
      system,
      ...
    }:
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        topConfig.flake.nixosModules.llamacpp
      ];

      # Hermes Agent Framework configuration
      services.hermes-agent = {
        enable = true;
        settings = {
          model = {
            provider = "custom";
            default = "gemma-4-E4B-it";
            base_url = "http://localhost:8081/v1";
            api_mode = "chat_completions";
          };
        };
        # Ensure the CLI is available in the system path
        addToSystemPackages = true;
      };
    };
}

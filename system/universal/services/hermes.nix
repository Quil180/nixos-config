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
      ];

      # Hermes Agent Framework configuration
      services.hermes-agent = {
        enable = true;
        settings = {
          model = {
            # Adding local model url on laptop
            provider = "custom";
            base_url = "http://localhost:8080/v1";
            api_mode = "chat_completions";
          };
        };
        # Ensure the CLI is available in the system path
        addToSystemPackages = true;
      };
    };
}

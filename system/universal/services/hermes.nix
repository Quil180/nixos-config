{ topConfig, lib, pkgs, ... }:
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
        topConfig.flake.nixosModules.openwebui
      ];

      # Hermes Agent Framework configuration
      services.hermes-agent = {
        enable = true;
        settings = {
          model = {
            provider = "custom";
            default = "harmonic-hermes-9b";
            base_url = "http://localhost:8081/v1";
            api_mode = "chat_completions";
          };
        };
        # Ensure the CLI is available in the system path
        addToSystemPackages = true;
      };

      # Llama.cpp with TurboQuant optimizations
      services.llama-cpp = {
        enable = true;
        package = inputs.llama-cpp-turboquant.packages.${system}.default;
        # Assuming model exists at this location (standard for this config)
        model = "/home/quil/Documents/llamacpp/harmonic-hermes-9b.Q4_K_M.gguf";
        port = 8081;
        extraFlags = [
          "--cache-type-k" "turbo3"
          "--cache-type-v" "turbo3"
          "-fa" "on" # Flash Attention required for TurboQuant
          "-c" "65536" # Large context window made viable by TurboQuant
          "--n-gpu-layers" "35" # Adjust based on 6800S VRAM
        ];
      };

      systemd.services.llama-cpp.environment = {
        # Force ROCm to use the correct GFX version for RX 6800S (G14 2022)
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
      };

      systemd.services.llama-cpp.serviceConfig = {
        User = "quil";
        Group = "users";
        DynamicUser = lib.mkForce false;
        ProtectHome = lib.mkForce false;
      };
    };
}

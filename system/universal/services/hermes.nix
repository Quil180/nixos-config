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
        topConfig.flake.nixosModules.openwebui
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

      # Llama.cpp with TurboQuant optimizations
      services.llama-cpp = {
        enable = true;
        package = inputs.llama-cpp-turboquant.packages.${system}.rocm;
        model = "/home/quil/Documents/llamacpp/gemma-4-e4b-it.Q4_K_M.gguf";
        port = 8081;
        extraFlags = [
          "--cache-type-k" "turbo3"
          "--cache-type-v" "turbo3"
          "-fa" "on" # Flash Attention required for TurboQuant
          "-c" "65536" # Large context window made viable by TurboQuant
          "--n-gpu-layers" "35" # Adjust based on 6800S VRAM
        ];
      };

      systemd.services.llama-cpp = {
        preStart = ''
          MODEL_DIR="/home/quil/Documents/llamacpp"
          MODEL_PATH="$MODEL_DIR/gemma-4-e4b-it.Q4_K_M.gguf"
          mkdir -p "$MODEL_DIR"
          if [ ! -f "$MODEL_PATH" ]; then
            echo "Downloading Gemma-4 model..."
            ${pkgs.curl}/bin/curl -L "https://huggingface.co/bartowski/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-e4b-it-Q4_K_M.gguf" -o "$MODEL_PATH"
            chown quil:users "$MODEL_PATH"
          fi
        '';
        environment = {
          # Force ROCm to use the correct GFX version for RX 6800S (G14 2022)
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        };
        serviceConfig = {
          User = "quil";
          Group = "users";
          DynamicUser = lib.mkForce false;
          ProtectHome = lib.mkForce false;
        };
      };
    };
}

{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.llamacpp =
    {
      pkgs,
      config,
      lib,
      inputs,
      ...
    }:

    {
      services.llama-cpp = {
        enable = true;
        # package = pkgs.llama-cpp.override { rocmSupport = true; };
        package = inputs.llama-cpp-turboquant.packages.${pkgs.stdenv.hostPlatform.system}.rocm;
        # model = "/home/quil/Documents/llamacpp/gemma-4-E4B-it-Q5_K_M.gguf";
        # model = "/home/quil/Documents/llamacpp/gemma-4-26B-A4B-it-UD-Q4_K_M.gguf"; # 21 cpu-moe for 8gb vram
        # model = "/home/quil/Documents/llamacpp/Qwen3.6-35B-A3B-UD-Q6_K.gguf"; # 33 cpu-moe for 8gb vram
        # model = "/home/quil/Documents/llamacpp/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"; # 31 cpu-moe for 8gb vram
        model = "/home/quil/Documents/llamacpp/granite-4.1-8b-Q4_K_M.gguf"; # 1 cpu-moe for 8gb vram
        port = 8081;
        extraFlags = [
          "--n-gpu-layers"
          "999"
          # "--n-cpu-moe"
          # "1" # adjust based on model
          "--no-mmap"
          "--mlock"
          "--cache-type-k"
          "turbo4"
          "--cache-type-v"
          "turbo3"
          # "-c"
          # "131072"
        ];
      };

      systemd.services.llama-cpp.environment = {
        # Force ROCm to use the correct GFX version for RX 6800S
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        HIP_VISIBLE_DEVICES = "0";
      };

      systemd.services.llama-cpp.serviceConfig = {
        User = "quil";
        Group = "users";
        DynamicUser = lib.mkForce false;
        ProtectHome = lib.mkForce false;

        LimitMEMLOCK = "infinity";
      };
    };
}

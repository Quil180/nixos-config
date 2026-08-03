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
      lib,
      username,
      ...
    }:
    {
      services.llama-cpp = {
        enable = true;
        # ROCm build targeted specifically for the G14's RX 6800S GPU
        package = pkgs.llama-cpp-rocm;
        settings = {
          hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:Q4_K_M";

          # Qwen sampling recommendations
          temp = 0.6;
          top-p = 0.95;
          top-k = 0; # 20 recommended but gpu doesnt support
          min-p = 0.0;

          # Speculative Decoding (MTP)
          spec-type = "draft-mtp";
          spec-draft-n-max = 2;

          # Server settings
          port = 8081;
          timeout = 600;

          # --- 1. Context Window & KV Cache Optimizations ---
          ctx-size = 32768; # 8192 or 32768
          image-min-tokens = 1024; # Required for image recognition
          cache-type-k = "q8_0"; # Quantizes KV cache to save VRAM
          cache-type-v = "q8_0"; # Essential to keep large contexts off your 8GB VRAM limit

          # --- 2. GPU Offloading & Speed ---
          n-gpu-layers = -1; # Forces maximum possible layers to the RX 6800S
          parallel = 1;
          batch-size = 2048; # Speeds up prompt processing (prefill)
          ubatch-size = 2048; # Increases parallel processing efficiency
          threads = 8; # Matches your G14's physical cores (prevents HT overhead)

          # --- 3. Advanced Memory & Attention Optimizations ---
          flash-attn = "on"; # Huge VRAM savings and speedup for attention
          load-mode = "none";
          reasoning-preserve = true;
          fit = "on";

          # Security warning
          api-key = "1234";
        };
      };

      systemd.services.llama-cpp = {
        environment = {
          # RX 6800S identifies as gfx1032; force ROCm override to supported gfx1030
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
          HIP_VISIBLE_DEVICES = "0";
          LLAMA_CACHE = "/home/${username}/Documents/llama.cpp";
        };
        serviceConfig = {
          User = username;
          Group = "users";
          DynamicUser = lib.mkForce false;
          ProtectHome = lib.mkForce false;
          LimitMEMLOCK = "infinity";
        };
      };
    };
}

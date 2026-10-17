_: {
  flake.nixosModules.llamacpp =
    {
      pkgs,
      lib,
      username,
      ...
    }:
    {
      # Stops llama-cpp while cardwire has the dGPU blocked (laptops only).
      imports = [ ./_gpu-coupling.nix ];

      services.llama-cpp = {
        enable = true;
        # ROCm build targeted specifically for the G14's RX 6800S GPU
        package = pkgs.llama-cpp-rocm;
        settings = {
          # hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_M";
          hf-repo = "huihui-ai/Huihui-Qwen3.6-35B-A3B-Claude-4.7-Opus-abliterated-MTP-GGUF:Q4_K";

          # Qwen sampling recommendations
          temp = 0.6;
          top-p = 0.95;
          top-k = 20; # 20 recommended but gpu doesnt support
          min-p = 0.05;
          presence-penalty = 0.0;
          repeat-penalty = 1.0;

          # Speculative Decoding (MTP)
          spec-type = "draft-mtp";
          spec-draft-n-max = 4;
          spec-draft-p-min = 0.6;

          # Server settings
          timeout = 300;

          # Cap generation per request (Qwen3.6 card recommends 32,768 output tokens)
          n-predict = 32768;

          # --- 1. Context Window & KV Cache Optimizations ---
          ctx-size = 131072; # 8192 or 32768 or 192640
          cache-type-k = "q4_0"; # Halves KV vs q8_0: 720 MiB vs 1360 MiB at 131072 cells
          cache-type-v = "q4_0"; # The freed ~640 MiB gets re-spent by fit on resident experts

          # --- 2. GPU Offloading & Speed ---
          fit = "on";
          fit-target = 256;
          parallel = 1;
          batch-size = 2048; # Speeds up prompt processing (prefill)
          ubatch-size = 2048; # Increases parallel processing efficiency
          threads = 6; # Matches your G14's physical cores (prevents HT overhead)

          # --- 3. Advanced Memory & Attention Optimizations ---
          flash-attn = "on"; # Huge VRAM savings and speedup for attention
          load-mode = "mlock";
          reasoning-preserve = true;
          metrics = true;
          no-mmproj = true;

          cache-prompt = true;
          cont-batching = true;
          warmup = true;
          reasoning = "auto";
          reasoning-budget = 8192;
          jinja = true;
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

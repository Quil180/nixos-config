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
          hf-repo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF:UD-Q4_K_XL";

          # Qwen recommendations
          temp = 0.6;
          top-p = 0.95;
          top-k = 20;
          min-p = 0.0;
          spec-type = "draft-mtp";
          spec-draft-n-max = 2;

          port = 8081;
          timeout = 600;
        };
      };

      systemd.services.llama-cpp = {
        environment = {
          # RX 6800S identifies as gfx1032; force ROCm override to supported gfx1030
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
          HIP_VISIBLE_DEVICES = "0";
          LLAMA_CACHE = "/home/${username}/Doccuments/llama.cpp";
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

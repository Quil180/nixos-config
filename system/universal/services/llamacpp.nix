{ pkgs, config, lib, ... }:

{
  imports = [
    ./openwebui.nix
  ];

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { rocmSupport = true; };
    # You MUST set a model for llama-cpp to start.
    # Download a GGUF model and point to it here.
    model = "/home/quil/Documents/llamacpp/model.gguf"; 
    port = 8081;
    extraFlags = [
      "--n-gpu-layers" "35" # Offload all layers to GPU (adjust based on model/VRAM)
      "--ctx-size" "4096"
    ];
  };

  systemd.services.llama-cpp.environment = {
    # Force ROCm to use the correct GFX version for RX 6800S
    HSA_OVERRIDE_GFX_VERSION = "10.3.0";
  };

  systemd.services.llama-cpp.serviceConfig = {
    User = "quil";
    Group = "users";
    DynamicUser = lib.mkForce false;
    ProtectHome = lib.mkForce false;
  };
}

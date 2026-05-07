{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.nixosModules.openwebui =
    { ... }:
    {
      services.open-webui = {
        enable = true;
        environment = {
          # Ollama backend (default port 11434)
          OLLAMA_BASE_URL = "http://localhost:11434";
          # OpenAI-compatible backend (llama.cpp runs on port 8081)
          OPENAI_API_BASE_URL = "http://localhost:8081/v1";
        };
      };
    };
}

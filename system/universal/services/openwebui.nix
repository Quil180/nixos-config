{ ... }:

{
  # Open WebUI - A user-friendly web interface for LLM backends
  # This module is imported by both ollama.nix and llamacpp.nix
  # The environment variables configure which backend(s) to use
  
  services.open-webui = {
    enable = true;
    environment = {
      # Ollama backend (default port 11434)
      OLLAMA_BASE_URL = "http://localhost:11434";
      # OpenAI-compatible backend (llama.cpp runs on port 8081)
      OPENAI_API_BASE_URL = "http://localhost:8081/v1";
    };
  };
}

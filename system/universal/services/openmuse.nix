{ topConfig, ... }:
{
  flake.nixosModules.openmuse =
    {
      pkgs,
      lib,
      config,
      username,
      ...
    }:
    let
      cfg = config.services.openmuse;

      # Check if local model inference backends are currently enabled on this host
      hasLlamacpp = config.services.llama-cpp.enable or false;
      hasOllama = config.services.ollama.enable or false;

      # Resolve effective backend:
      # If "auto" (default):
      #   1. llama.cpp if active (:8080)
      #   2. ollama if active (:11434)
      #   3. OpenRouter by default when neither local backend is enabled
      effectiveBackend =
        if cfg.backend != "auto" then
          cfg.backend
        else if hasLlamacpp then
          "llamacpp"
        else if hasOllama then
          "ollama"
        else
          "openrouter";

      normalizedOpenRouterModel =
        if lib.hasPrefix "deepseek-" cfg.openRouterModel then
          "deepseek/" + cfg.openRouterModel
        else
          cfg.openRouterModel;

      # Resolved model & endpoint configuration based on effective backend
      resolvedConfig =
        if effectiveBackend == "llamacpp" then
          {
            baseUrl = cfg.llamacppEndpoint;
            model =
              if cfg.model != null then
                cfg.model
              else
                "openai/" + (config.services.llama-cpp.settings.hf-repo or "local-model");
            apiKey = "not-needed";
            chatCompletions = "true";
            providerName = "Local llama.cpp (${cfg.llamacppEndpoint})";
          }
        else if effectiveBackend == "ollama" then
          {
            baseUrl = cfg.ollamaEndpoint;
            model = if cfg.model != null then cfg.model else "openai/ollama";
            apiKey = "ollama";
            chatCompletions = "true";
            providerName = "Local Ollama (${cfg.ollamaEndpoint})";
          }
        else
          {
            # OpenRouter default
            baseUrl = cfg.openRouterEndpoint;
            model = if cfg.model != null then cfg.model else "openai/" + normalizedOpenRouterModel;
            apiKey = ""; # Will be resolved at runtime from secret/env file if empty
            chatCompletions = "true";
            providerName = "OpenRouter (${cfg.openRouterEndpoint})";
          };

      # CLI helper script for status, manual updates, and log inspection
      openmuseCli = pkgs.writeShellScriptBin "openmuse" ''
        set -euo pipefail

        DATA_DIR="${cfg.dataDir}"
        REPO_DIR="$DATA_DIR/repo"

        show_help() {
          echo "OpenMuse Assistant Management CLI"
          echo "Usage: openmuse <command>"
          echo ""
          echo "Commands:"
          echo "  status       Display service status and active AI model backend"
          echo "  update       Pull latest changes from GitHub and reinstall packages"
          echo "  logs         Follow OpenMuse systemd logs"
          echo "  web          Show local web UI URL"
          echo "  env          Show generated runtime environment (.env)"
          echo ""
        }

        cmd="''${1:-status}"

        case "$cmd" in
          status)
            echo "=========================================="
            echo " OpenMuse Service Status"
            echo "=========================================="
            echo "Active Backend : ${effectiveBackend}"
            echo "Provider       : ${resolvedConfig.providerName}"
            echo "Model          : ${resolvedConfig.model}"
            echo "Base URL       : ${resolvedConfig.baseUrl}"
            echo "API Port       : ${toString cfg.port}"
            echo "Web Port       : ${toString cfg.webPort}"
            echo "State Dir      : $DATA_DIR"
            echo "=========================================="
            systemctl --no-pager status openmuse.service || true
            ;;
          update)
            echo "Updating OpenMuse in $REPO_DIR..."
            if [ -d "$REPO_DIR/.git" ]; then
              cd "$REPO_DIR"
              git pull --rebase
              pnpm install
              echo "Restarting openmuse service..."
              systemctl restart openmuse.service
              echo "Done!"
            else
              echo "Repository directory $REPO_DIR not found. Start the service first."
            fi
            ;;
          logs)
            journalctl -u openmuse.service -u openmuse-web.service -f
            ;;
          web)
            echo "OpenMuse Web UI available at: http://localhost:${toString cfg.webPort}"
            ;;
          env)
            if [ -f "$REPO_DIR/.env" ]; then
              cat "$REPO_DIR/.env"
            else
              echo "No .env found in $REPO_DIR"
            fi
            ;;
          help|--help|-h)
            show_help
            ;;
          *)
            echo "Unknown command: $cmd"
            show_help
            exit 1
            ;;
        esac
      '';
    in
    {
      # Pull in Docker (required for OpenMuse's terminal and browser container workers)
      imports = [ topConfig.flake.nixosModules.docker ];

      options.services.openmuse = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the CopilotKit OpenMuse personal AI assistant.";
        };

        dataDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/openmuse";
          description = "State and persistent data directory for OpenMuse.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8787;
          description = "Port for the OpenMuse Hono API server.";
        };

        webPort = lib.mkOption {
          type = lib.types.port;
          default = 8081;
          description = "Port for the OpenMuse Web / Expo UI.";
        };

        backend = lib.mkOption {
          type = lib.types.enum [
            "auto"
            "llamacpp"
            "ollama"
            "openrouter"
          ];
          default = "auto";
          description = ''
            Backend selection for model inferences:
            - "auto" (default): Checks if llamacpp or ollama is active on the host.
              If neither is enabled, defaults automatically to OpenRouter.
            - "llamacpp": Force local llama.cpp endpoint (:8080).
            - "ollama": Force local Ollama endpoint (:11434).
            - "openrouter": Force OpenRouter API.
          '';
        };

        model = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Override model identifier. When null, uses backend default.";
        };

        # Local endpoints
        llamacppEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:8080/v1";
          description = "OpenAI-compatible endpoint for local llama.cpp.";
        };

        ollamaEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "http://127.0.0.1:11434/v1";
          description = "OpenAI-compatible endpoint for local Ollama.";
        };

        # OpenRouter configuration (used by default when local models are off)
        openRouterEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "https://openrouter.ai/api/v1";
          description = "API endpoint for OpenRouter.";
        };

        openRouterModel = lib.mkOption {
          type = lib.types.str;
          default = "deepseek/deepseek-v4.1-flash-1017";
          description = "Default model to request when using OpenRouter.";
        };

        openRouterApiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default =
            if (builtins.pathExists ../../../secrets/openrouter_api_key.age) then
              config.age.secrets.openrouter_api_key.path
            else
              null;
          description = ''
            Path to file containing OpenRouter API key (defaults to agenix secret
            openrouter_api_key if secrets/openrouter_api_key.age exists).
            If null, key can also be supplied in environmentFile or manually in
            /var/lib/openmuse/openrouter.key.
          '';
        };

        copilotKitApiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default =
            if (builtins.pathExists ../../../secrets/copilotkit_api_key.age) then
              config.age.secrets.copilotkit_api_key.path
            else
              null;
          description = ''
            Path to file containing CopilotKit Intelligence API key (defaults to agenix secret
            copilotkit_api_key if secrets/copilotkit_api_key.age exists).
            If null, key can also be read from /var/lib/openmuse/copilotkit.key.
          '';
        };

        copilotKitApiKey = lib.mkOption {
          type = lib.types.str;
          default = "cpk_local_dev";
          description = ''
            CopilotKit Intelligence API key. Defaults to cpk_local_dev for local
            workspaces without cloud sync.
          '';
        };

        workspaceMode = lib.mkOption {
          type = lib.types.enum [
            "sample"
            "live"
          ];
          default = "sample";
          description = "Workspace mode. 'sample' provides local fixtures; 'live' requires Google OAuth.";
        };

        agentBackend = lib.mkOption {
          type = lib.types.enum [
            "model"
            "sample"
            "agui"
          ];
          default = "model";
          description = "Agent backend. 'model' delegates tasks to the configured LLM.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default =
            if (builtins.pathExists ../../../secrets/openmuse_env.age) then
              config.age.secrets.openmuse_env.path
            else
              null;
          description = "Optional path to systemd EnvironmentFile for additional credentials.";
        };

        enableBrowserWorker = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to start the Playwright Chromium browser worker container.";
        };

        enableComputer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable the isolated Docker Linux computer workspace.";
        };

        enableWeb = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to start the OpenMuse Web / Mobile client service.";
        };
      };

      config = lib.mkIf cfg.enable {
        # Agenix secret for OpenRouter API key
        age.secrets.openrouter_api_key =
          lib.mkIf (builtins.pathExists ../../../secrets/openrouter_api_key.age)
            {
              file = ../../../secrets/openrouter_api_key.age;
              owner = username;
              group = "users";
              mode = "0400";
            };

        # Agenix secret for CopilotKit Intelligence API key
        age.secrets.copilotkit_api_key =
          lib.mkIf (builtins.pathExists ../../../secrets/copilotkit_api_key.age)
            {
              file = ../../../secrets/copilotkit_api_key.age;
              owner = username;
              group = "users";
              mode = "0400";
            };

        # Agenix secret for OpenMuse environment credentials (Google, Live Mode, Worker Token)
        age.secrets.openmuse_env = lib.mkIf (builtins.pathExists ../../../secrets/openmuse_env.age) {
          file = ../../../secrets/openmuse_env.age;
          owner = username;
          group = "users";
          mode = "0400";
        };

        # Impermanence: persist state (cloned repo, PGlite DB, browser profile, workspace files)
        persist.directories = [
          {
            directory = cfg.dataDir;
            user = username;
            group = "users";
            mode = "0750";
          }
        ];

        # Ensure state directory exists and is owned by the user
        systemd.tmpfiles.rules = [
          "d ${cfg.dataDir} 0750 ${username} users -"
          "Z ${cfg.dataDir} 0750 ${username} users -"
        ];

        # Add CLI and runtime dependencies to system packages
        environment.systemPackages = with pkgs; [
          openmuseCli
          nodejs
          pnpm
          git
        ];

        # Main OpenMuse API server service
        systemd.services.openmuse = {
          description = "CopilotKit OpenMuse AI Assistant API Server";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "docker.service"
          ]
          ++ lib.optional hasLlamacpp "llama-cpp.service"
          ++ lib.optional hasOllama "ollama.service";
          wants = [ "docker.service" ];

          path = with pkgs; [
            git
            nodejs
            pnpm
            docker
            bash
            coreutils
            gnugrep
            curl
          ];

          serviceConfig = {
            Type = "simple";
            User = username;
            Group = "users";
            SupplementaryGroups = [ "docker" ];
            StateDirectory = "openmuse";
            StateDirectoryMode = "0750";
            WorkingDirectory = cfg.dataDir;
            Restart = "always";
            RestartSec = 5;
            DynamicUser = lib.mkForce false;
            ProtectHome = lib.mkForce false;
          }
          // lib.optionalAttrs (cfg.environmentFile != null) {
            EnvironmentFile = cfg.environmentFile;
          };

          preStart = ''
                        REPO_DIR="${cfg.dataDir}/repo"

                        # 1. Clone or update repository if not present
                        if [ ! -d "$REPO_DIR/.git" ]; then
                          echo "Cloning CopilotKit/openmuse into $REPO_DIR..."
                          git clone --depth 1 https://github.com/CopilotKit/openmuse.git "$REPO_DIR"
                        fi

                        cd "$REPO_DIR"

                        # Source extra credentials from environmentFile if present
                        ${lib.optionalString (cfg.environmentFile != null) ''
                          if [ -f "${toString cfg.environmentFile}" ]; then
                            set -a
                            source "${toString cfg.environmentFile}"
                            set +a
                          fi
                        ''}

                        EFFECTIVE_WORKSPACE_MODE="${cfg.workspaceMode}"
                        if [ -n "''${OPENMUSE_ACCESS_KEY:-}" ] || [ -n "''${GOOGLE_CLIENT_ID:-}" ]; then
                          EFFECTIVE_WORKSPACE_MODE="live"
                        fi

                        # 2. Determine model API key
                        RESOLVED_API_KEY="${resolvedConfig.apiKey}"
                        ${lib.optionalString (cfg.openRouterApiKeyFile != null) ''
                          if [ -f "${toString cfg.openRouterApiKeyFile}" ]; then
                            RESOLVED_API_KEY="$(cat "${toString cfg.openRouterApiKeyFile}" | tr -d '\n\r ')"
                          fi
                        ''}
                        if [ -z "$RESOLVED_API_KEY" ] && [ -f "${cfg.dataDir}/openrouter.key" ]; then
                          RESOLVED_API_KEY="$(cat "${cfg.dataDir}/openrouter.key" | tr -d '\n\r ')"
                        fi

                        # 3. Determine CopilotKit Intelligence API key
                        RESOLVED_CPK_KEY="${cfg.copilotKitApiKey}"
                        ${lib.optionalString (cfg.copilotKitApiKeyFile != null) ''
                          if [ -f "${toString cfg.copilotKitApiKeyFile}" ]; then
                            RESOLVED_CPK_KEY="$(cat "${toString cfg.copilotKitApiKeyFile}" | tr -d '\n\r ')"
                          fi
                        ''}
                        if [ -f "${cfg.dataDir}/copilotkit.key" ]; then
                          FILE_CPK_KEY="$(cat "${cfg.dataDir}/copilotkit.key" | tr -d '\n\r ')"
                          if [ -n "$FILE_CPK_KEY" ]; then
                            RESOLVED_CPK_KEY="$FILE_CPK_KEY"
                          fi
                        fi
                        if [ -z "$RESOLVED_CPK_KEY" ]; then
                          RESOLVED_CPK_KEY="cpk_local_dev"
                        fi

                        # 4. Generate .env file
                        cat > "$REPO_DIR/.env" <<EOF
            # Generated automatically by NixOS openmuse module
            PORT=${toString cfg.port}
            HOST=127.0.0.1
            WORKSPACE_MODE=''${EFFECTIVE_WORKSPACE_MODE}
            AGENT_BACKEND=${cfg.agentBackend}
            CPK_INTELLIGENCE_API_KEY=''${RESOLVED_CPK_KEY}
            OPENAI_BASE_URL=${resolvedConfig.baseUrl}
            MODEL=${resolvedConfig.model}
            OPENAI_CHAT_COMPLETIONS=${resolvedConfig.chatCompletions}
            OPENAI_API_KEY=''${RESOLVED_API_KEY}
            OPENROUTER_API_KEY=''${RESOLVED_API_KEY}
            WEB_SEARCH_ENABLED=true
            EOF

                        if [ -n "''${OPENMUSE_ACCESS_KEY:-}" ]; then
                          echo "OPENMUSE_ACCESS_KEY=''${OPENMUSE_ACCESS_KEY}" >> "$REPO_DIR/.env"
                        fi
                        if [ -n "''${TOKEN_ENCRYPTION_KEY:-}" ]; then
                          echo "TOKEN_ENCRYPTION_KEY=''${TOKEN_ENCRYPTION_KEY}" >> "$REPO_DIR/.env"
                        fi
                        if [ -n "''${GOOGLE_CLIENT_ID:-}" ]; then
                          echo "GOOGLE_CLIENT_ID=''${GOOGLE_CLIENT_ID}" >> "$REPO_DIR/.env"
                        fi
                        if [ -n "''${GOOGLE_CLIENT_SECRET:-}" ]; then
                          echo "GOOGLE_CLIENT_SECRET=''${GOOGLE_CLIENT_SECRET}" >> "$REPO_DIR/.env"
                        fi
                        if [ -n "''${WORKER_TOKEN:-}" ]; then
                          echo "BROWSER_WORKER_URL=http://127.0.0.1:8790" >> "$REPO_DIR/.env"
                          echo "WORKER_TOKEN=''${WORKER_TOKEN}" >> "$REPO_DIR/.env"
                        fi
                        ${lib.optionalString cfg.enableComputer ''
                          echo "COMPUTER_ENABLED=true" >> "$REPO_DIR/.env"
                          echo "COMPUTER_IMAGE=openmuse-computer:local" >> "$REPO_DIR/.env"
                          if ! docker image inspect openmuse-computer:local >/dev/null 2>&1; then
                            echo "Building openmuse-computer:local docker image..."
                            docker build -t openmuse-computer:local "$REPO_DIR/apps/computer"
                          fi
                        ''}

                        # 5. Install dependencies if node_modules missing
                        if [ ! -d "$REPO_DIR/node_modules" ]; then
                          echo "Installing OpenMuse dependencies with pnpm..."
                          pnpm install --frozen-lockfile || pnpm install
                        fi
          '';

          script = ''
            cd "${cfg.dataDir}/repo"
            # Launch OpenMuse API backend
            exec pnpm dev
          '';
        };

        # Web UI service (running Expo / Web app)
        systemd.services.openmuse-web = lib.mkIf cfg.enableWeb {
          description = "CopilotKit OpenMuse Web Interface";
          wantedBy = [ "multi-user.target" ];
          after = [ "openmuse.service" ];
          requires = [ "openmuse.service" ];

          path = with pkgs; [
            git
            nodejs
            pnpm
            bash
            coreutils
          ];

          serviceConfig = {
            Type = "simple";
            User = username;
            Group = "users";
            WorkingDirectory = cfg.dataDir;
            Restart = "always";
            RestartSec = 5;
            DynamicUser = lib.mkForce false;
            ProtectHome = lib.mkForce false;
          };

          script = ''
            REPO_DIR="${cfg.dataDir}/repo"
            while [ ! -d "$REPO_DIR/node_modules" ]; do
              echo "Waiting for OpenMuse repository and dependencies to be initialized..."
              sleep 3
            done
            cd "$REPO_DIR"
            # Launch Web interface on the configured port
            PORT=${toString cfg.webPort} exec pnpm --dir apps/mobile web --port ${toString cfg.webPort} || exec pnpm dev:web
          '';
        };

        # Browser worker container service
        systemd.services.openmuse-browser = lib.mkIf cfg.enableBrowserWorker {
          description = "CopilotKit OpenMuse Playwright Browser Worker";
          wantedBy = [ "multi-user.target" ];
          after = [
            "docker.service"
            "openmuse.service"
          ];
          wants = [ "docker.service" ];

          path = with pkgs; [
            docker
            docker-compose
            coreutils
            bash
          ];

          serviceConfig = {
            Type = "simple";
            User = username;
            Group = "users";
            SupplementaryGroups = [ "docker" ];
            WorkingDirectory = "${cfg.dataDir}/repo";
            Restart = "always";
            RestartSec = 5;
          };

          script = ''
            REPO_DIR="${cfg.dataDir}/repo"
            while [ ! -f "$REPO_DIR/.env" ]; do
              echo "Waiting for OpenMuse .env to be generated..."
              sleep 2
            done

            cd "$REPO_DIR"
            set -a
            source .env
            set +a

            if [ -z "''${WORKER_TOKEN:-}" ]; then
              echo "Browser worker disabled (WORKER_TOKEN not set in environment)."
              exit 0
            fi

            export WORKER_TOKEN
            echo "Starting browser worker on http://127.0.0.1:8790..."
            exec docker compose -f infra/compose.yaml up --build
          '';

          preStop = ''
            cd "${cfg.dataDir}/repo"
            docker compose -f infra/compose.yaml down || true
          '';
        };
      };
    };
}

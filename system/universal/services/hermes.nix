_: {
  flake.nixosModules.hermes =
    {
      inputs,
      config,
      lib,
      username,
      ...
    }:
    let
      osConfig = config;
    in
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
        # The CLI/gateway's per-user state (~/.hermes) and the messaging
        # gateway's user service live in the user's home; declarable from here
        # on hosts with home-manager integrated.
        # (In a nested module: `options` may only decide the shape of `config`.)
        (
          { options, ... }:
          {
            config = lib.optionalAttrs (options ? home-manager) {
              home-manager.users.${username} =
                { config, ... }:
                let
                  # The Python environment `hermes gateway install` runs the
                  # gateway from; taken from the package, so it follows updates.
                  venv = osConfig.services.hermes-agent.package.passthru.hermesVenv;
                  hermesHome = "${config.home.homeDirectory}/.hermes";
                in
                {
                  persist.directories = [
                    ".hermes"
                    ".local/state/hermes"
                  ];

                  # The messaging gateway (Discord, Telegram, ...), as
                  # `hermes gateway install` writes it, run against ~/.hermes.
                  # Not upstream's home-manager module: that one would take
                  # over ~/.hermes/config.yaml and .env, which are set up by
                  # hand. The old hand-installed unit of the same name is moved
                  # aside to *.backup on the first switch.
                  systemd.user.services.hermes-gateway = {
                    Unit = {
                      Description = "Hermes Agent Gateway - Messaging Platform Integration";
                      StartLimitIntervalSec = 0;
                    };
                    Service = {
                      Type = "simple";
                      ExecStart = "${venv}/bin/python -m hermes_cli.main gateway run";
                      WorkingDirectory = hermesHome;
                      Environment = [
                        "PATH=${venv}/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
                        "VIRTUAL_ENV=${venv}"
                        "HERMES_HOME=${hermesHome}"
                        "HERMES_SUPERVISED_CHILD=1"
                      ];
                      Restart = "always";
                      RestartSec = 5;
                      RestartForceExitStatus = 75;
                      SuccessExitStatus = 75;
                      RestartPreventExitStatus = 78;
                      KillMode = "mixed";
                      KillSignal = "SIGTERM";
                      ExecReload = "/run/current-system/sw/bin/kill -USR1 $MAINPID";
                      ExecStopPost = "-${venv}/bin/python -m gateway.cgroup_cleanup";
                      TimeoutStopSec = 70;
                    };
                    Install.WantedBy = [ "default.target" ];
                  };
                };
            };
          }
        )
      ];

      # Sessions, memories, cron jobs and the workspace.
      persist.directories = [
        {
          directory = config.services.hermes-agent.stateDir;
          inherit (config.services.hermes-agent) user group;
          mode = "2770";
        }
      ];

      # Hermes Agent framework. The model/provider is deliberately host-side:
      # snowflake talks to the local llama.cpp endpoint on :8080, a server
      # talks to an API provider. Set services.hermes-agent.settings.model in
      # the host config, not here — `settings` merges by recursiveUpdate, so
      # two modules setting the same key resolve by import order, silently.
      services.hermes-agent = {
        enable = true;

        # Put the CLI on the system PATH and export HERMES_HOME so
        # interactive shells share state with the gateway service.
        addToSystemPackages = true;
      };
    };
}

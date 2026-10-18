_: {
  flake.nixosModules.hermes =
    {
      inputs,
      config,
      ...
    }:
    {
      imports = [
        inputs.hermes-agent.nixosModules.default
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

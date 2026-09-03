{
  topConfig,
  lib,
  pkgs,
  ...
}:
{
  flake.homeModules.pi =
    { pkgs, inputs, dotfilesDir, ... }:
    {
      home.packages = with pkgs; [
        pi-coding-agent
        nodejs # so npm is installed for pi extensions
      ];

      # Pi coding agent configuration stored in ~/.pi/agent/
      home.file = {
        # Default provider and model settings
        ".pi/agent/settings.json".text = builtins.toJSON {
          lastChangelogVersion = "0.83.0";
          theme = "dark";
          packages = [
            # "git:github.com/huggingface/pi-llama" # llamacpp integration
            "npm:@narumitw/pi-lsp" # lsp support
            "npm:pi-web-access" # crawling websites
            "npm:@narumitw/pi-goal" # goals for continuous
            "npm:pi-extension-toolkit" # pi extension toolkit helper
            "npm:pi-hashline-edit-pro" # better edit/read
          ];
        };

        # Trust configuration - which directories the agent can access
        # ".pi/agent/trust.json".text = builtins.toJSON {
        #   "${dotfilesDir}" = true;
        # };

        # Git repository extensions (empty by default, no API keys needed)
        # auth.json is intentionally NOT managed declaratively here so that pi
        # can write its own auth/credentials. We only make sure the directory
        # exists and is owned by the user.
        ".pi/agent/.keep".text = "";
      };

      # pi needs to write to ~/.pi (settings, auth, sessions, models store).
      # Home-manager file activations can leave ~/.pi or its contents owned by
      # root when it runs as root during a system switch (e.g. right after a pi
      # update). This activation repairs ownership/perms on every switch so pi
      # can always modify its own user data.
      #
      # To get the correct owner even when running as root during a system
      # rebuild, we take the owner of the user's home directory itself.
      home.activation.repairPiOwnership = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        home_dir="''${HOME:-$PWD}"
        make_dir=${pkgs.coreutils}/bin/mkdir
        make_chown=${pkgs.coreutils}/bin/chown
        make_chmod=${pkgs.coreutils}/bin/chmod
        make_stat=${pkgs.coreutils}/bin/stat

        "$make_dir" -p "$home_dir/.pi/agent" || true

        # Match ownership of ~/.pi to the owner of the home directory. This is
        # correct whether we run as the user themselves or as root (system).
        owner="$("$make_stat" -c '%u:%g' "$home_dir" 2>/dev/null || true)"
        if [ -n "$owner" ]; then
          "$make_chown" -R "$owner" "$home_dir/.pi" 2>/dev/null || true
        else
          "$make_chmod" -R u+rwX "$home_dir/.pi" 2>/dev/null || true
        fi
      '';
    };
}

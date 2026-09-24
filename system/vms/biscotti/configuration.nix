{
  topConfig,
  ...
}:
{
  configurations.nixos.biscotti.module =
    {
      ...
    }:
    {
      imports = with topConfig.flake.nixosModules; [ vm_base ];

      networking.hostName = "biscotti";
      system.stateVersion = "26.11";

      # ---- Nix remote builder.
      #
      # server_notes: 8 vCPU / 8 GB is ~1 GB per thread, so cap max-jobs below
      # the vCPU count for C++-heavy builds rather than relying on RAM alone to
      # avoid OOM kills.
      nix.settings = {
        max-jobs = 4;
        cores = 0; # let each build use all cores
        trusted-users = [
          "root"
          "quil"
        ];
      };

      # The builder accepts remote connections over SSH: the user, key and
      # the LAN/WireGuard-scoped port 22 all come from server_base.

      # Optional: serve the built results as a binary cache.
      # services.nix-serve = {
      #   enable = true;
      #   secretKeyFile = "/var/lib/nix-serve/nix-serve.sec";
      # };

      # On snowflake/moraine, point at this builder with:
      #   nix.buildMachines = [ {
      #     hostName = "biscotti";
      #     systems = [ "x86_64-linux" ];
      #     maxJobs = 4;
      #     protocol = "ssh-ng";
      #     sshUser = "quil";
      #   } ];
      #   nix.distributedBuilds = true;
    };

  configurations.nixos.biscotti.tags = [
    "vm"
    "server"
    "builder"
  ];
}

{pkgs, ...}:
{
	environment.etc = {
		"nix/nix.custom.conf" = {
			mode = "0755";
			text = pkgs.lib.mkForce ''
eval-cores = 0
			'';
		};
		"determinate/config.json" = {
			mode = "0755";
			text = pkgs.lib.mkForce ''
{
  "garbageCollector": {
    "strategy": "automatic"
  },
  "builder": {
    "state": "enabled",
    "memoryBytes": 8589934592,
    "cpuCount": 1
  }
}
			'';
		};
  };
}

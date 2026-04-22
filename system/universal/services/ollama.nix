{ topConfig, lib, pkgs, ... }:
{
  flake.nixosModules.ollama = 
{pkgs, lib, ...}:
{
	imports = [ topConfig.flake.nixosModules.openwebui ];
	# nixpkgs.overlays = [
	# 	(final: prev: {
	# 		# This is the corrected overlay.
	# 		# It uses overrideAttrs to directly change the build process.
	# 		ollama = prev.ollama.overrideAttrs (oldAttrs: {
	# 			# The Ollama build script specifically looks for this environment variable.
	# 			AMDGPU_TARGETS = "gfx1032";
	# 		});
	# 	})
	# ];

	services = {
		ollama = {
			enable = true;
			package = pkgs.ollama-rocm;
			models = "/home/quil/Documents/llamacpp/models";
			environmentVariables = {
				# This forces Ollama to use your Radeon RX 6800S
				HSA_OVERRIDE_GFX_VERSION = "10.3.0";
				# Only use the dedicated GPU (6800S), not the integrated 680M
				ROCR_VISIBLE_DEVICES = "0";
			};
		};
		
		# Open WebUI is configured in llamacpp.nix
	};
	
	systemd.services.ollama.serviceConfig = {
		User = "quil";
		Group = "users";
		DynamicUser = lib.mkForce false;
		ProtectHome = lib.mkForce false;
	};

	systemd.tmpfiles.rules = [
		"d /home/quil/Documents/llamacpp/models 0755 quil users -"
	];
}
;
}

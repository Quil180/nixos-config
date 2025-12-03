{...}:
{
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
			acceleration = "rocm";
			environmentVariables = {
				# This forces Ollama to use your Radeon RX 6800S
				HSA_OVERRIDE_GFX_VERSION = "10.3.0";
				OLLAMA_MODELS = "/home/quil/Documents/llamacpp/models";
			};
			user = "quil";
			group = "users";
		};
		
		# Open WebUI is configured in llamacpp.nix
	};
	
	systemd.services.ollama.serviceConfig = {
		DynamicUser = lib.mkForce false;
		ProtectHome = lib.mkForce false;
	};
}

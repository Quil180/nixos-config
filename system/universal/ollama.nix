{...}:
{
	services = {
		ollama = {
			enable = true;
			acceleration = "rocm";
			loadModels = [
				"gpt-oss-20b"
			];
		};
		open-webui = {
			enable = true;
		};
	};
}

{inputs, system, ...}: {
  home.packages = [
    inputs.quickshell.packages.${system}.default
  ];

	xdg.configFile = {
		"quickshell/bar.qml" = {
      source = ./bar.qml;
      force = true;
    };
	};
}

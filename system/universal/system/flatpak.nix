_: {
  flake.nixosModules.flatpak = _: {
    # System-wide remotes and installed apps.
    persist.directories = [ "/var/lib/flatpak" ];

    services.flatpak.enable = true;
  };
}

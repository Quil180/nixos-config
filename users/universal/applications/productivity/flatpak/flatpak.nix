{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # enabling core things, if not enabled
  xdg.enable = true;

  services.flatpak = {
    packages = [
      "org.freedesktop.portal.Settings"
      "io.github.flattool.Warehouse"
      "org.vinegarhq.Sober"
      "net.waterfox.waterfox"
    ];
  };

  home.sessionVariablesExtra = ''
    export XDG_DATA_DIRS="''${HOME}/.local/share/flatpak/exports/share:''${XDG_DATA_DIRS}"
  '';

  home.packages = with pkgs; [
    flatpak
  ];
}

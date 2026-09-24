_: {
  flake.homeModules.flatpak =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Fetch the bundle outside of the flatpak module
      vkSumiBundle = pkgs.fetchurl {
        url = "https://github.com/reakjra/vkSumi/releases/download/v0.0.7/vkSumi-25.08.flatpak";
        sha256 = "sha256-4uDoDcbKG/e9Oc6FAwtcVz4ZmetQDJlg8+bkZf0GtX8=";
      };
    in
    {
      # enabling core things, if not enabled
      xdg.enable = true;

      services.flatpak = {
        enable = true;
        update = {
          onActivation = true;
          auto.enable = true;
        };
        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
        packages = [
          "io.github.flattool.Warehouse"
          # "org.vinegarhq.Sober" # Roblox
          "io.github.benjamimgois.goverlay"
          "org.freedesktop.Platform.VulkanLayer.MangoHud//25.08" # req for goverlay
          "org.freedesktop.Platform.VulkanLayer.vkBasalt//25.08" # req for goverlay
          "app.fluxer.Fluxer"
        ];
      };

      home = {
        packages = with pkgs; [
          flatpak
        ];
        activation.installVKSumi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          # Install the fetched flatpak bundle. 
          # $DRY_RUN_CMD prevents execution during a dry-run/build.
          # || true prevents the whole switch from failing if the flatpak is already installed.
          $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install --user -y ${vkSumiBundle} || true
        '';
        # Append Flatpak exports to XDG_DATA_DIRS so launchers can find desktop files
        sessionVariablesExtra = ''
          export XDG_DATA_DIRS="$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
        '';
      };
    };
}

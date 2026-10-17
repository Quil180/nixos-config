{
  lib,
  ...
}:
let
  # Base Flatpak infrastructure module: sets up Flatpak services, Flathub remote, auto-updates,
  # XDG data directories, and the flatpak binary, but DOES NOT install any applications by default.
  baseFlatpakModule =
    {
      pkgs,
      lib,
      ...
    }:
    {
      xdg.enable = lib.mkDefault true;

      services.flatpak = {
        enable = lib.mkDefault true;
        update = {
          onActivation = lib.mkDefault true;
          auto.enable = lib.mkDefault true;
        };
        remotes = lib.mkDefault [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
      };

      home = {
        packages = with pkgs; [
          flatpak
        ];
        # Append Flatpak exports to XDG_DATA_DIRS so application launchers find desktop files
        sessionVariablesExtra = ''
          export XDG_DATA_DIRS="$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
        '';
      };
    };

  # Helper to construct a Flathub application module.
  # Automatically pulls in base flatpak infrastructure.
  mkFlathubApp =
    pkg:
    { ... }:
    {
      imports = [ baseFlatpakModule ];
      services.flatpak.packages = if builtins.isList pkg then pkg else [ pkg ];
    };

  # Helper to construct a Flatpak single-file bundle installer module (e.g. from GitHub releases).
  # Automatically pulls in base flatpak infrastructure.
  mkFlatpakBundle =
    {
      name,
      url,
      sha256 ? null,
      hash ? null,
    }:
    {
      pkgs,
      lib,
      ...
    }:
    let
      bundle = pkgs.fetchurl (
        {
          inherit url;
        }
        // (
          if hash != null then
            { inherit hash; }
          else if sha256 != null then
            { inherit sha256; }
          else
            { }
        )
      );
    in
    {
      imports = [ baseFlatpakModule ];
      home.activation."installFlatpak_${name}" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # Install the fetched flatpak bundle.
        # $DRY_RUN_CMD prevents execution during a dry-run/build.
        # || true prevents the whole switch from failing if the flatpak is already installed.
        $DRY_RUN_CMD ${pkgs.flatpak}/bin/flatpak install --user -y ${bundle} || true
      '';
    };

  # Scalable registry of Flathub applications.
  # To add any new Flathub application, simply add a key-value pair here!
  # It will automatically be exposed as topConfig.flake.homeModules.<key>.
  flathubApps = {
    fluxer = "app.fluxer.Fluxer";
    warehouse = "io.github.flattool.Warehouse";
    sober = "org.vinegarhq.Sober";
    goverlay = [
      "io.github.benjamimgois.goverlay"
      "org.freedesktop.Platform.VulkanLayer.MangoHud//25.08" # req for goverlay
      "org.freedesktop.Platform.VulkanLayer.vkBasalt//25.08" # req for goverlay
    ];
  };

  # Auto-generate modules for all apps in flathubApps
  generatedFlathubModules = lib.mapAttrs (_: mkFlathubApp) flathubApps;

  # vkSumi standalone bundle flatpak
  vkSumiModule = mkFlatpakBundle {
    name = "vkSumi";
    url = "https://github.com/reakjra/vkSumi/releases/download/v0.0.7/vkSumi-25.08.flatpak";
    sha256 = "sha256-4uDoDcbKG/e9Oc6FAwtcVz4ZmetQDJlg8+bkZf0GtX8=";
  };
in
{
  flake.homeModules = generatedFlathubModules // {
    # Base Flatpak module (no applications pre-installed)
    flatpak = baseFlatpakModule;

    # Bundle applications
    vkSumi = vkSumiModule;

    # Convenience aliases for casing & naming flexibility
    "vk-sumi" = vkSumiModule;
    VkSumi = vkSumiModule;
    Fluxer = generatedFlathubModules.fluxer;
    Warehouse = generatedFlathubModules.warehouse;
    Goverlay = generatedFlathubModules.goverlay;
    Sober = generatedFlathubModules.sober;
  };
}

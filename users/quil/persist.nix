_: {
  # The home-side twin of the system's `persist.*` option: a home module
  # declares the paths (relative to ~) its app needs kept, e.g.
  #   persist.directories = [ ".config/kicad" ];
  # Always declared (flake.nix adds it to every home build), so modules set it
  # unconditionally; it only takes effect when the profile imports `persist`.
  flake.homeModules.persistOptions =
    { lib, ... }:
    let
      entries =
        what:
        lib.mkOption {
          type = with lib.types; listOf (either str (attrsOf anything));
          default = [ ];
          description = "Home ${what} (relative to ~) to keep, when the profile imports `persist`.";
        };
    in
    {
      options.persist = {
        directories = entries "directories";
        files = entries "files";
      };
    };

  flake.homeModules.persist =
    { config, ... }:
    {
      # Standalone home-manager needs this to bypass the "manual import" assertion
      home._nixosModuleImported = true;

      # Only what isn't owned by one app module; those declare their own
      # through `persist.directories`.
      home.persistence."/persist" = {
        directories = [
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
          "Desktop"
          "winboat"
          ".ssh"
          ".gnupg"
          ".config/github-copilot"
          ".config/teamviewer"
          ".local/share/direnv"
          ".local/share/keyrings"
          ".local/share/icc"
          ".cache/nix"
          ".cache/tealdeer"
          ".dotfiles"
        ]
        ++ config.persist.directories;
        files = [
          ".bash_history"
        ]
        ++ config.persist.files;
      };
    };
}

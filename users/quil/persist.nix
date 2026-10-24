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
    {
      config,
      lib,
      options,
      ...
    }:
    {
      # impermanence's NixOS module both provides `home.persistence` (to homes
      # integrated into the system) and does the bind mounts. A standalone
      # home, or a host without the system `persist` module, has neither, so
      # there this is a no-op: the lists are still declared, nothing mounts.
      # (`options` may only decide the shape of `config`.)
      config = lib.optionalAttrs (options.home ? persistence) {
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
            # 0700: the VM test showed fresh persist folders default to 0755,
            # which gpg warns about (and ~/.ssh shouldn't be world-readable).
            {
              directory = ".ssh";
              mode = "0700";
            }
            {
              directory = ".gnupg";
              mode = "0700";
            }
            ".config/github-copilot"
            ".config/teamviewer"
            ".local/share/direnv"
            ".local/share/keyrings"
            ".local/share/icc"
            ".cache/nix"
            ".cache/tealdeer"
            ".dotfiles"
            ".claude" # Claude Code: settings, history, project memory
            ".pi" # pi agent
            ".config/pi-hashline-edit-pro" # pi extension config
            ".config/dconf" # settings GTK apps save themselves
            ".local/state/wireplumber" # default audio devices and volumes
            ".local/share/applications" # Steam game shortcuts, URL handlers
            ".local/share/icons" # their icons
          ]
          ++ config.persist.directories;
          files = [
            ".bash_history"
            # Claude Code's login and global config. A single file is a bind
            # mount, which a save-by-rename can't replace; if Claude Code ever
            # fails to save its config, this is why.
            ".claude.json"
          ]
          ++ config.persist.files;
        };
      };
    };
}

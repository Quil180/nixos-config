# NixOS installer ISO.
#
# Shares its configuration body with the offline variant through
# installer-module.nix; the two hosts differ only in preloaded content:
#
#   nixosConfigurations.installer         — the normal online ISO (~1 GB):
#                                           boots to a root/nixos shell, bundles
#                                           the repo at /etc/dotfiles and the
#                                           `nixos-install-drive` command.
#   nixosConfigurations.installer-offline — same ISO but with the snowflake and
#                                           moraine system closures, home-manager
#                                           activation packages and their disko
#                                           scripts in isoImage.storeContents, so
#                                           the whole install runs with no
#                                           network at all. The ISO grows to
#                                           10-20 GB because it contains
#                                           Hyprland, games, ROCm, firmware.
#
# The offline host is wired on the flake-outputs side (see flake.nix): its
# preloaded content has to be computed there, because doing it inside a
# `configurations.nixos` module means importing config.flake.nixosConfigurations
# while that attrset is still being enumerated (eval-order cycle).
#
# Build:     nix build .#iso                  (or .#iso-offline)
# Boot it, then run `nixos-install-drive --host <host>` (--help for options).
_:
let
  installerModule = import ../../lib/installer-module.nix;
in
{
  configurations.nixos.installer = {
    module = installerModule {
      storeContents = [ ];
      targetsText = "";
    };
  };
}

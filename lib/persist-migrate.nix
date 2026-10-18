# Builds the `persist-migrate` script (flake.nix: packages/apps.persist-migrate).
#
# Single source of truth for the script: system/universal/system/persist-migrate.sh.
# It copies a running machine's state into /persist before its first boot with
# impermanence; see the header of the script for the steps.
{ pkgs }:
pkgs.writeShellApplication {
  name = "persist-migrate";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.diffutils # cmp
    pkgs.findutils
    pkgs.gnused
    pkgs.jq
    pkgs.util-linux # mountpoint, findmnt
  ];
  # nix and sudo come from the system: the script must use the machine's own
  # nix (same flake registry/settings) and its setuid sudo wrapper.
  text = builtins.readFile ../system/universal/system/persist-migrate.sh;
}

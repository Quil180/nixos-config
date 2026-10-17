# Builds the `nixos-install-drive` installer script.
#
# Single source of truth for the script: system/installer/nixos-install-drive.sh.
# Two consumers wrap it:
#   - flake.nix (perSystem): packages.install + apps.install, so
#     `nix run github:Quil180/nixos-config#install` works from a stock ISO
#   - system/installer/iso.nix: bundled into the installer ISO's systemPackages
#
# The script is a writeShellApplication: tools are pinned via runtimeInputs and
# shipped in the same derivation (no reliance on the live-ISO environment).
{
  pkgs,
  diskoPkg,
  lib,
}:
let
  # The workstation user key from secrets/secrets.nix. The installer refuses
  # to install with any other key: a wrong key could never decrypt the agenix
  # secrets (incl. the quil/root passwords) on first boot.
  secretsNix = builtins.readFile ../secrets/secrets.nix;
  # builtins.match is full-string anchored, so match the user_quil line on its
  # own and keep the base64 capture (POSIX ERE — no \s). A deleted/renamed
  # entry fails the build loudly instead of silently shipping a lax installer.
  userQuilBase64 = builtins.concatStringsSep "" (
    builtins.concatMap (
      line:
      let
        m = builtins.match ''[ ]*user_quil[ ]*=[ ]*"ssh-ed25519[ ]+([A-Za-z0-9+/=]+) quil@snowflake";'' line;
      in
      if m == null then [ ] else m
    ) (lib.splitString "\n" secretsNix)
  );
  expectedUserQuilKey =
    if userQuilBase64 == "" then
      throw "could not find the user_quil key in secrets/secrets.nix"
    else
      "ssh-ed25519 ${userQuilBase64}";
in
pkgs.writeShellApplication {
  name = "nixos-install-drive";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnused
    pkgs.gnugrep
    pkgs.gawk
    pkgs.git
    pkgs.curl
    pkgs.openssh # ssh-keygen, ssh
    pkgs.util-linux # lsblk, findmnt, mount, umount
    pkgs.cryptsetup
    pkgs.networkmanager # nmcli
    pkgs.nixos-install-tools # nixos-install, nixos-enter
    pkgs.nix # nix build/copy/eval, nix-build
    diskoPkg
  ];
  runtimeEnv = {
    NIXOS_INSTALL_EXPECTED_KEY = expectedUserQuilKey;
  };
  text = builtins.readFile ../system/installer/nixos-install-drive.sh;
}

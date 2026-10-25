# Shared module body for the `installer` / `installer-offline` flake hosts.
#
# The `extra` parameter carries the offline-ISO content, so the caller decides:
#   storeContents = [ ]                     (online: nothing preloaded)
#   storeContents = [ <closures> ... ]       (offline: hosts' toplevels,
#                                             destroyFormatMount scripts and
#                                             home-manager activation packages)
#   targetsText   = ""                      (online)
#   targetsText   = <lookup table>          (offline: parsed by --offline)
#
# IMPORTANT: the offline data must be computed by the CALLER (flake.nix, at the
# flake-outputs layer), never inside a `configurations.nixos` module. Computing
# it there means importing config.flake.nixosConfigurations at the same moment
# that attrset is still being enumerated — an eval-order cycle.
extra:
{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
{
  imports = [
    ("${inputs.nixpkgs}" + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # flake.nix's nixosConfigurations wiring adds the agenix and disko modules
  # to every host. The ISO has no secrets to decrypt (decryption happens on
  # the target after first boot, keyed to the user key at /home/quil/.ssh)
  # and manages no host disks (disko is shipped as a CLI package instead).
  disko.devices = { };

  # Bundle the repository (minus .git, the wallpapers submodule content and
  # editor cruft) at /etc/dotfiles — the flake the installer builds from.
  environment.etc."dotfiles" = {
    source = builtins.path {
      name = "dotfiles-source";
      path = ../.;
      filter =
        p: _t:
        builtins.baseNameOf p != ".git"
        && builtins.baseNameOf p != "result"
        && builtins.baseNameOf p != "wallpapers"
        && builtins.baseNameOf p != ".pi"
        && builtins.baseNameOf p != ".claude";
    };
  };

  # Everything `nixos-install-drive` and the install itself touch.
  environment.systemPackages = [
    inputs.disko.packages.${system}.disko
    pkgs.nixos-install-tools # nixos-install, nixos-enter
    pkgs.curl
    ((import ./install-script.nix) {
      inherit pkgs lib;
      diskoPkg = inputs.disko.packages.${system}.disko;
    })
  ];

  # sshd is enabled by the installer profile; authorize the workstation key
  # for both accounts so the install can be driven over ssh and scp is one
  # way to deliver the agenix key (~/.ssh/id_ed25519) to the ISO.
  users.users.root.openssh.authorizedKeys.keys = [
    (builtins.readFile ../system/keys/id_snowflake.pub)
  ];
  users.users.nixos.openssh.authorizedKeys.keys = [
    (builtins.readFile ../system/keys/id_snowflake.pub)
  ];

  services.getty.helpLine = lib.mkForce ''
    The "nixos" account has an empty password (root too); passwordless sudo works.

    To install onto the target disk, run:
        nixos-install-drive --host snowflake
    (options: --host/--device/--key/--yes/--offline — see `nixos-install-drive --help`)

    To drive the install from another machine over ssh:
        ssh nixos@<this-ip>
        scp ~/.ssh/id_ed25519 nixos@<this-ip>:/tmp/id_ed25519
  '';

  # Latest kernel so new hardware (e.g. the RX 9070 XT in moraine) works.
  # OpenZFS is frequently broken on latest kernels; disable ZFS on the ISO.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  # `nix build/eval <path>#...` must work from the ISO.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Offline variant only: the prebuilt closures, plus the lookup table the
  # script reads under --offline. Harmless (empty) on the online ISO.
  isoImage.storeContents = extra.storeContents;
  environment.etc."installer/offline-targets".text = extra.targetsText;
}

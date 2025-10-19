{ pkgs, lib, ... }:
{
  # ASUS G14 Patched Kernel based off of Arch Linux Kernel
  # Source: https://github.com/Kamokuma5/nix_config/blob/main/nixos_config/nixos_modules/asus-kernel.nix
  boot.kernelPackages =
    let
      linux_g14_pkg =
        {
          fetchzip,
          fetchgit,
          buildLinux,
          ...
        }@args:
        let
          # Get all patches from the asus-linux for Arch project
          patch_dir = fetchgit {
            fetchSubmodules = false;
            url = "https://gitlab.com/dragonn/linux-g14.git/";
            rev = "858a4a1b130abb1449e162fa05c300145f3d9450";
            hash = "sha256-Z5QQb7XV9bbFRyjSlJDI6PcNuN7mGOnp11amC2+erY4=";
          };

          ## Get all top-level patch files from patch_dir
          patchFiles = builtins.readDir patch_dir;

          ## Filter for only `.patch` files
          unsortedPatchList = lib.mapAttrsToList (
            name: _:
            builtins.trace "Found patch: ${name}" {
              inherit name;
              patch = "${patch_dir}/${name}";
            }
          ) (lib.filterAttrs (name: _type: lib.hasSuffix ".patch" name) patchFiles);

          patchList = builtins.sort (a: b: a.name < b.name) unsortedPatchList;
        in
        buildLinux (
          args
          // rec {
            inherit patchList;

            version = "6.16.8-arch3";

            # Get kernel source from arch GitHub repo
            defconfig = "${patch_dir}/config";

            src = fetchzip {
              url = "https://github.com/archlinux/linux/archive/refs/tags/v${version}.tar.gz";
              hash = "sha256-ikJ1/eDrfcdtF+LFSzAnuqzZcOZifkkhTaqWrLiP9Pk=";
            };
          }
          // (args.argsOverride or { })
        );
      linux_g14 = pkgs.callPackage linux_g14_pkg { };
    in
    pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_g14);

  services = {
    # supergfxd controls GPU switching
    supergfxd.enable = true;

    # ASUS specific software. This also installs asusctl.
    asusd = {
      enable = true;
      enableUserService = true;
    };

    # Dependency of asusd
    power-profiles-daemon.enable = true;
  };
}


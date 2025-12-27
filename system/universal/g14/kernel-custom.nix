{ pkgs, lib, ... }:

let
  # Fetch the linux-g14 repo
  linux-g14-repo = pkgs.fetchgit {
    url = "https://gitlab.com/asus-linux/linux-g14.git";
    fetchSubmodules = false;
    rev = "b8f38b0b9649ea9c4e4f8b4e3c17719a2c84a74b";
    hash = "sha256-o25NP9BNsnafN967bE+EmwWfUW9hvfaTR0pgsAky25M=";
  };

  # Helper to find all .patch files in the directory
  findPatches = dir: 
    let
      files = builtins.readDir dir;
      patchFiles = lib.filterAttrs (name: type: type == "regular" && 
                                                lib.hasSuffix ".patch" name && 
                                                name != "0001-platform-x86-asus-armoury-Fix-error-code-in-mini_led.patch" && 
                                                name != "0001-platform-x86-asus-armoury-fix-only-DC-tunables-being.patch" && 
                                                name != "0002-platform-x86-asus-armoury-fix-mini-led-mode-show.patch" && 
                                                name != "0003-platform-x86-asus-armoury-add-support-for-FA507UV.patch" && 
                                                name != "PATCH-v10-00-11-HID-asus-Fix-ASUS-ROG-Laptop-s-Keyboard-backlight-handling-id1-id2-pr_err.patch" && 
                                                name != "sys-kernel_arch-sources-g14_files-0004-more-uarches-for-kernel-6.15.patch"
                                   ) files;
    in
      lib.mapAttrsToList (name: _: {
        name = name;
        patch = "${dir}/${name}";
      }) patchFiles;

in {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linuxPackages_latest.kernel.override {
    argsOverride = {
      # Append the G14 patches to the standard latest kernel patches
      kernelPatches = pkgs.linuxPackages_latest.kernel.kernelPatches ++ (findPatches linux-g14-repo);
      extraMeta.branch = "6.18.2"; # Update this to match approximate version if needed
    };
  }));
}

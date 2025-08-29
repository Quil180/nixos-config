# Simple overlay to disable running pygls tests during Nix builds
self: super: {
  python3Packages = super.python3Packages // {
    pygls = super.python3Packages.pygls.overrideAttrs (old: {
      doCheck = false;
      checkPhase = ''
        echo "Skipping pygls tests via overlay"
      '';
    });
  };
}

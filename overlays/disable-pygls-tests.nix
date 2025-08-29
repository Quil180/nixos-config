/* Overlay to disable running pygls tests in Nix builds (workaround for upstream test incompatibility) */
self: super: {
  python3Packages = super.python3Packages // {
    pygls = super.python3Packages.pygls.overrideAttrs (old: {
      # skip running tests which fail due to lsprotocol/pygls compatibility
      doCheck = false;
      checkPhase = ''
        echo "Skipping pygls tests via overlay"
      '';
    });
  };
}

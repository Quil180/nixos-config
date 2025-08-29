self: super: {
  python3Packages = super.python3Packages // {
    pygls = super.python3Packages.pygls.overrideAttrs (old: {
      # attempt to make pygls importable with different lsprotocol type names
      postPatch = ''
        echo "Patching pygls for lsprotocol compatibility"
        if [ -f "$src/pygls/workspace/text_document.py" ]; then
          substituteInPlace "$src/pygls/workspace/text_document.py" \
            --replace 'TextDocumentContentChangeEvent_Type1' 'TextDocumentContentChangeEvent' || true
        fi
      '' + (old.postPatch or '');
      # leave tests off to speed iteration (can be enabled later)
      doCheck = false;
    });
  };
}

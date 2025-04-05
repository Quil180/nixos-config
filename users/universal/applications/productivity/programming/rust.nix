{inputs, ...}: {
  home.packages = with inputs.rust-overlay.packages.${inputs.rust-overlay.rustChannel}; [
    rust-analyzer
    rustfmt
    cargo-audit
    carg-generate
    cargo-outdated
    cargo-update
    cargo-udeps
    cargo-watch
    clippy
  ];
}

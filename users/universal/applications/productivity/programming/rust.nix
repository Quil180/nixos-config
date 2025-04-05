{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    rust-analyzer
    rustfmt
    cargo-audit
    cargo-generate
    cargo-outdated
    cargo-update
    cargo-udeps
    cargo-watch
    clippy
  ];
}

let
  snowflake = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDW8eBDa2ExHWmN7QIP9GRzmxDEI4lYa1D837vWtKbjk";
in {
  "secrets1.age".publicKeys = [
    snowflake
  ];
}

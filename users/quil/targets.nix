{ topConfig, ... }:
{
  # One home-manager target per host, named "<user>@<host>".
  #
  # home-manager's flake resolution probes $USER@$(hostname -f), then
  # $USER@$(hostname), then $USER@$(hostname -s) before falling back to a bare
  # "$USER" — so `home-manager switch --flake <dotfiles>` with no attribute
  # (exactly what the `updh` alias runs) selects the right target per machine,
  # mirroring how `nixos-rebuild --flake <dotfiles>` (the `upds` alias) picks
  # the host by hostname.
  #
  # Host traits are NOT repeated here: they are declared once on the host's
  # nixos entry (configurations.nixos.<host>.tags) and flow into the matching
  # home target automatically.
  configurations.home."quil@snowflake".module = {
    imports = [ topConfig.flake.homeModules.quil ];
  };

  configurations.home."quil@moraine".module = {
    imports = [ topConfig.flake.homeModules.quil ];
  };
}

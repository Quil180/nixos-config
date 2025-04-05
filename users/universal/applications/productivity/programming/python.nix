{
  config,
  pkgs,
  ...
}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      vunit-hdl
      edalize
      yowasp-yosys
      cocotb
    ]);
in {
  home.packages = with pkgs; [
    pythonEnv
  ];
}

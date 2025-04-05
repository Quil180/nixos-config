{pkgs, ...}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      (ps.buildPythonPackage rec {
        pname = "vunit-hdl";
        version = "4.7.0"; # replace with the desired version
        src = ps.fetchPypi {
          inherit pname version;
        };
      })
      edalize
      (ps.buildPythonPackage rec {
        pname = "yowasp-yosys";
        version = "0.51.0.0"; # replace with the desired version
        src = ps.fetchPypi {
          inherit pname version;
        };
      })
      cocotb
    ]);
in {
  home.packages = with pkgs; [
    pythonEnv
  ];
}

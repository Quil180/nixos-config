{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.python = 
{pkgs, ...}: let
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      (ps.buildPythonPackage rec {
        pname = "vunit_hdl";
        version = "4.7.0"; # replace with the desired version
        format = "setuptools";
        src = ps.fetchPypi {
          inherit pname version;
          sha256 = "sha256-ol+5kbq9LqhRlm4NvcX02PZJqz5lDjASmDsp/V0Y8i0=";
        };
      })
      edalize
      /*
      # yowasp-yosys no longer provides source tarballs on PyPI. 
      # Migration to wheel-based distribution or Codeberg source is needed.
      (ps.buildPythonPackage rec {
        pname = "yowasp-yosys";
        version = "0.51.0.0"; # replace with the desired version
        format = "setuptools";
        src = ps.fetchPypi {
          inherit pname version;
        };
      })
      */
      cocotb
    ]);
in {
  home.packages = with pkgs; [
    pythonEnv
  ];
}
;
}

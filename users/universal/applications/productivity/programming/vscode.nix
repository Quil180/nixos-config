{pkgs, ...}: {
  home.packages = with pkgs; [
    vscode
    vscodeExtensions.vscodevim
    vscodeExtensions.ms-vscode.cpptools
    vscodeExtensions.martinring.c.makefile-tools
    vscodeExtensions.martinring.cmake-tools
    vscodeExtensions.bbenoist.Nix-ide
  ];
}

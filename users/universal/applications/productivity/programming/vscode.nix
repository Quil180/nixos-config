{pkgs, ...}: {
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        github.copilot

				# Languages
        ms-vscode.cpptools-extension-pack
        yzhang.markdown-all-in-one
				ms-vscode.makefile-tools
				ms-python.python
      ];
    };
  };
}

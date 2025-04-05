{pkgs, ...}: {
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
        ms-vscode.cpptools-extension-pack
        github.copilot
      ];
    };
  };
}

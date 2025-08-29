{pkgs, ...}: {
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        github.copilot
				eamodio.gitlens

				# Languages
        ms-vscode.cpptools-extension-pack
        yzhang.markdown-all-in-one
				ms-vscode.makefile-tools
				ms-python.python
      ];
			profiles.default.userSettings = {
				"chat.editor.fontFamily" = "iosevka";
				"chat.editor.fontSize" = 16.0;
				"debug.console.fontFamily" = "iosevka";
				"debug.console.fontSize" = 16.0;
				"editor.fontFamily" = "iosevka";
				"editor.fontSize" = 16.0;
				"editor.inlayHints.fontFamily" = "iosevka";
				"editor.inlineSuggest.fontFamily" = "iosevka";
				"editor.minimap.sectionHeaderFontSize" = 10.285714285714286;
				"markdown.preview.fontFamily" = "iosevka";
				"markdown.preview.fontSize" = 16.0;
				"scm.inputFontFamily" = "iosevka";
				"scm.inputFontSize" = 14.857142857142858;
				"screencastMode.fontSize" = 64.0;
				"terminal.integrated.fontSize" = 16.0;
				"workbench.colorTheme" = "Stylix";
				"chat.tools.autoApprove" = true;
				"chat.agent.maxRequests" = 250;
				"git.autofetch" = true;
			};
    };
  };
}

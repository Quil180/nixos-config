{ topConfig, lib, pkgs, ... }:
{
  flake.homeModules.persist = 
{
  # Standalone home-manager needs this to bypass the "manual import" assertion
  home._nixosModuleImported = true;

  home.persistence."/persist" = {
    directories = [
      "Documents"
      "Downloads"
      "Music"
      "Pictures"
      "Videos"
      "Desktop"
      "winboat"
      ".ssh"
      ".gnupg"
      ".mozilla" # Firefox
      ".config/discord"
      ".config/nixcord"
      ".config/gh"
      ".config/github-copilot"
      ".config/kicad"
      ".config/libreoffice"
      ".config/teamviewer"
      ".local/share/direnv"
      ".local/share/zsh"
      ".local/share/nvim"
      ".local/share/keyrings"
      ".local/share/Steam"
      ".local/share/PrismLauncher"
      ".local/share/zoxide"
      ".local/share/icc"
      ".cache/nix"
      ".cache/tealdeer"
      ".dotfiles"
    ];
    files = [
      ".bash_history"
    ];
    allowOther = true;
  };
}
;
}

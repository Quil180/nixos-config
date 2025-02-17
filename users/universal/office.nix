{pkgs, ...}:
{
  home.packages = (with pkgs; [
    libreoffice-qt6
    hunspell
    hunspellDicts.en_US
  ]);
}

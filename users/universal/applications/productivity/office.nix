_: {
  flake.homeModules.office = { pkgs, ... }: {
    persist.directories = [ ".config/libreoffice" ];

    home.packages = with pkgs; [
      libreoffice-qt6
      hunspell
      hunspellDicts.en_US

      corefonts
      vista-fonts
    ];
  };
}

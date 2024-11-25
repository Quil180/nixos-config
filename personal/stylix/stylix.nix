{pkgs, ...}:

{
  stylix = {
    enable = true;
    autoEnable = true;
    image = ../../wallpapers/eepy_myne.png;

    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };
  };
}

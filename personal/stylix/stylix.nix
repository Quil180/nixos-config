{pkgs, ...}:

{
  stylix = {
    enable = true;
    image = ../../wallpapers/eepy_myne.png;
    polarity = "dark";
    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };

    targets.console.enable = true;
    targets.nixvim.enable = true;

  };
}

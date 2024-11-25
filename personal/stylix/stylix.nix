{pkgs, ...}:

{
  stylix = {
    enable = true;
    image = ../../wallpapers/eepy_myne.png;
  
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };

    targets.console.enable = true;
    targets.nixvim.enable = true;

  };
}

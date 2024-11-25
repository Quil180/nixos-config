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

    stylix.targets.console.enable = true;
    stylix.targets.nixvim.enable = true;

  };
}

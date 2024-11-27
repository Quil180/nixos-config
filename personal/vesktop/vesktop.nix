{pkgs, inputs, ...}:

{
  imports = [
    inputs.nixcord.homeManagerModules.nixcord
  ];

  home.packages = ( with pkgs; [
    vesktop
  ]);

  
}

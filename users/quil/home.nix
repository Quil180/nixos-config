{ topConfig, lib, pkgs, ... }:
{
  configurations.home.quil.module = 
{pkgs, username, inputs, ...}: {
  imports = [ topConfig.flake.homeModules.persist topConfig.flake.homeModules.hyprland topConfig.flake.homeModules.bash topConfig.flake.homeModules.chromium topConfig.flake.homeModules.firefox topConfig.flake.homeModules.music topConfig.flake.homeModules.neovim topConfig.flake.homeModules.password-manager topConfig.flake.homeModules.ranger topConfig.flake.homeModules.vivaldi topConfig.flake.homeModules.games topConfig.flake.homeModules.filezilla topConfig.flake.homeModules.git topConfig.flake.homeModules.kicad topConfig.flake.homeModules.latex topConfig.flake.homeModules.office topConfig.flake.homeModules.zoom topConfig.flake.homeModules.cpp topConfig.flake.homeModules.verilog topConfig.flake.homeModules.rust topConfig.flake.homeModules.python topConfig.flake.homeModules.antigravity topConfig.flake.homeModules.vscode topConfig.flake.homeModules.stylix topConfig.flake.homeModules.discord topConfig.flake.homeModules.revolt topConfig.flake.homeModules.flatpak ];

  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  };

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
    };
    packages = with pkgs; [
      age # secrets management
      brightnessctl # brightness control
      foot # terminal emulator
      mpv # terminal video player
      networkmanagerapplet # network manager tray
      pavucontrol # sound control GUI
      wl-clipboard # clipboard
      zoxide # better cd

      gemini-cli # temporarily putting here for the sake of not needing nix-shell command
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityFile = "/home/${username}/.ssh/id_snowflake";
    };
  };

  programs.home-manager.enable = true;
}
;
}

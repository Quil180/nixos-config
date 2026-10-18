_: {
  flake.homeModules.bitwarden = { pkgs, ... }: {

    persist.directories = [ ".config/Bitwarden" ];
    home.packages = with pkgs; [
      bitwarden-desktop
    ];

    # Start with the graphical session (Hyprland's session runs under
    # systemd; ~/.config/autostart is not processed there).
    systemd.user.services.bitwarden = {
      Unit = {
        Description = "Bitwarden";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.bitwarden-desktop}/bin/bitwarden --autostart";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}

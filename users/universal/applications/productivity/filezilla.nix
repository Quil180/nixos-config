_: {
  flake.homeModules.filezilla = { pkgs, ... }: {
    home.packages = with pkgs; [
      filezilla
    ];
  };
}

{pkgs, ...}: {
  stylix = {
    enable = true;
    cursor = {
      package = pkgs.inputs.rose-pine-hyprcursor.packages.${pkgs.system}.default;
      name = "rose-pine-hyprcursor";
      size = 24;
    };
  };
}

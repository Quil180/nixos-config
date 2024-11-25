{self, ...}:

{
  programs.nixvim = {
    plugins = {
      bufferline.enable = true;

      # dependencies are below
      web-devicons.enable = true;
    };
  };
}

{...}: {
  services.flatpak = {
    enable = true;
    packages = [
      # {
      #   appId = "com.brave.Browser";
      #   origin = "flathub";
      # }
      # "com.obsproject.Studio"

      "net.waterfox.waterfox"
    ];
    remotes = [
      # how to add a remote if i want too
      # name = "flathub-beta"; location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
    ];
  };
}

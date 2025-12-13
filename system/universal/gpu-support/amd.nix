{ pkgs, ... }: {
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver = {
    enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      # OpenCL support
      extraPackages = with pkgs; [
        rocmPackages.clr.icd 
      ];
    };
  };

  # System packages for monitoring
  environment.systemPackages = with pkgs; [
    clinfo # Verify OpenCL
    lact   # AMD Control Center (GUI)
  ];

  # Enable the LACT daemon
  systemd = {
    packages = with pkgs; [ lact ];
    services.lactd.wantedBy = ["multi-user.target"];
  };
}

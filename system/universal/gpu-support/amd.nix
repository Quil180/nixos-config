{pkgs, ...}: {
  boot.initrd.kernelModules = ["amdgpu"];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        rocmPackages.clr.icd # OpenCL
      ];
    };
  };

  services.xserver = {
    enable = true;
    videoDrivers = ["amdgpu"];
  };

  environment.systemPackages = with pkgs; [
    clinfo # used to ensure opencl is setup correctly
    lact # for overclocking/undervolting gpus!
  ];

  systemd = {
    packages = with pkgs; [
      lact
    ];
    services.lactd.wantedBy = ["multi-user.target"];

    # HIP Install
    tmpfiles.rules = let
      rocmEnv = pkgs.symlinkJoin {
        name = "rocm-combined";
        paths = with pkgs.rocmPackages; [
          rocblas
          hipblas
          clr
        ];
      };
    in [
      "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
    ];
  };
}

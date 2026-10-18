_: {
  flake.nixosModules.amd =
    {
      pkgs,
      lib,
      username,
      ...
    }:
    {
      # Mesa's and RADV's compiled-shader caches live in the user's home;
      # without them games stutter while rebuilding them after every boot.
      # Declarable from here on hosts with home-manager integrated.
      # (In a nested module: `options` may only decide the shape of `config`.)
      imports = [
        (
          { options, ... }:
          {
            config = lib.optionalAttrs (options ? home-manager) {
              home-manager.users.${username}.persist.directories = [
                ".cache/mesa_shader_cache"
                ".cache/radv_builtin_shaders"
              ];
            };
          }
        )
      ];

      services = {
        lact.enable = true;
      };

      hardware = {
        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = with pkgs; [
            libva-vdpau-driver
            libvdpau-va-gl
          ];
        };
        firmware = [
          pkgs.linux-firmware
        ];
      };

      # System packages for monitoring
      environment.systemPackages = with pkgs; [
        clinfo
      ];
    };
}

_: {
  flake.nixosModules.goverlay =
    {
      pkgs,
      lib,
      ...
    }:
    let
      vksumi = pkgs.stdenv.mkDerivation rec {
        pname = "vksumi";
        version = "0.1.0";
        src = pkgs.fetchFromGitHub {
          owner = "reakjra";
          repo = "vkSumi";
          rev = "v${version}";
          hash = "sha256-YgEXoMvqrRytYHPrR1C82KfRxMn6EBF1J9H2Ww0ybT0=";
        };
        nativeBuildInputs = with pkgs; [
          meson
          ninja
          pkg-config
          glslang
        ];
        buildInputs = with pkgs; [
          vulkan-headers
          vulkan-loader
          libx11
        ];
      };

      low-latency-layer = pkgs.stdenv.mkDerivation rec {
        pname = "low-latency-layer";
        version = "0.2.0";
        src = pkgs.fetchFromGitHub {
          owner = "Korthos-Software";
          repo = "low_latency_layer";
          rev = "v${version}";
          hash = "sha256-mnGAH0m19wOkWEowpcPRHXQSc6HGYW+CFYxjPF2onk4=";
        };
        nativeBuildInputs = [ pkgs.cmake ];
        buildInputs = with pkgs; [
          vulkan-headers
          vulkan-loader
          vulkan-utility-libraries
        ];
      };

      vkbasalt = pkgs.vkbasalt.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          ln -s vkbasalt/libvkbasalt.so $out/lib/libvkbasalt.so
        '';
      });

      goverlay = pkgs.goverlay.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          # Un-wrap bgmod and bgmod-uninstaller because they are Free Pascal console binaries
          # that read /proc/self/exe to discover their config files. The makeCWrapper breaks this.
          cp -f $out/libexec/.bgmod-wrapped $out/libexec/bgmod
          cp -f $out/libexec/.bgmod-uninstaller-wrapped $out/libexec/bgmod-uninstaller
        '';
      });
    in
    {
      # Enable GameMode daemon and permissions for gamemoderun
      programs.gamemode.enable = lib.mkDefault true;

      # Goverlay application and required libraries/dependencies
      environment.systemPackages = [
        goverlay
        pkgs.mangohud
        vkbasalt
        vksumi
        low-latency-layer
        pkgs.qt6Packages.libqtpas
      ];

      # Make Vulkan implicit layers discoverable for Goverlay and Vulkan applications
      environment.pathsToLink = [ "/share/vulkan" ];
      environment.etc."vulkan/implicit_layer.d".source =
        "/run/current-system/sw/share/vulkan/implicit_layer.d";
    };
}

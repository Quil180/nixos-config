_: {
  flake.nixosModules.cardwire =
    { lib, tags, ... }:
    {
      # GPU mode switching via eBPF LSM hooks — the successor to supergfxctl.
      # It blocks /dev/dri + sysfs access with -ENOENT instead of unbinding PCI,
      # so no logout and no driver unload: card1/card2 keep their numbering.
      # Laptop-gated: integrated/smart need exactly two GPUs (iGPU + dGPU), and
      # the external-display override assumes the HDMI/DP ports hang off the dGPU.
      services.cardwired = lib.mkIf (builtins.elem "laptop" tags) {
        enable = true;
        settings = {
          # Re-apply each GPU's block state after manual-mode fiddling.
          auto_apply_gpu_state = true;
          # AMD-only laptop (RX 6800S) — nothing NVIDIA to hide.
          experimental_nvidia_block = false;
          # On battery -> integrated (dGPU blocked); on AC -> the mode below.
          # Driven by UPower's OnBattery property, so it also applies at daemon
          # start and flips within ~a second of plugging/unplugging.
          battery_auto_switch = true;
          battery_auto_switch_mode = "hybrid";
          # G14 HDMI-A-1 is wired to the dGPU: unblock it while a display is
          # plugged in, then restore the requested mode on unplug.
          external_display_auto_switch = true;
        };
      };
    };
}

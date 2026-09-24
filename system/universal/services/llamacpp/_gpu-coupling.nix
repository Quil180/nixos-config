# Plain NixOS module, imported only by `llamacpp` (the leading underscore
# keeps import-tree from loading it as a flake-parts module).
{
  config,
  lib,
  pkgs,
  tags,
  ...
}:
let
  # Ties llama-cpp to cardwire's GPU mode: while the dGPU is blocked
  # (integrated) llama-cpp is stopped, and it comes back once the dGPU is
  # available again (hybrid/manual/smart). cardwire's own battery
  # auto-switch lands on integrated, so unplugging stops llama-cpp too.
  coupling = pkgs.writeShellApplication {
    name = "llamacpp-gpu-coupling";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      systemd
    ];
    text = ''
      BUS=org.opengamingcollective.cardwire
      OBJ=/org/opengamingcollective/cardwire
      IFACE=org.opengamingcollective.cardwire.Mode
      FLAG=/run/llamacpp-gpu-coupling/gpu-blocked
      UNIT=llama-cpp.service
      POLL=30

      log() { printf 'llamacpp-gpu-coupling: %s\n' "$*" >&2; }

      # Numeric cardwire mode: 0 integrated, 1 hybrid, 2 manual, 3 smart.
      # Empty when the daemon is not answering.
      mode_now() {
        busctl get-property "$BUS" "$OBJ" "$IFACE" Mode 2>/dev/null | awk 'NR == 1 { print $2 }'
      }

      # $1 = mode, $2 = initial|change
      apply() {
        case "$1" in
          0)
            # dGPU is hidden from userspace: mark it, then take llama-cpp down
            # so it releases its VRAM instead of sitting on a blocked device.
            mkdir -p "$(dirname "$FLAG")"
            [ -e "$FLAG" ] || : > "$FLAG"
            if systemctl is-active --quiet "$UNIT"; then
              log "mode=integrated ($2): stopping $UNIT, dGPU is blocked"
              systemctl stop "$UNIT"
            fi
            ;;
          1 | 2 | 3)
            # dGPU available again: clear the flag. On a transition bring
            # llama-cpp back; an initial run never starts it.
            rm -f "$FLAG"
            if [ "$2" = change ] && ! systemctl is-active --quiet "$UNIT"; then
              log "mode=$1 ($2): starting $UNIT, dGPU is available"
              systemctl start --no-block "$UNIT"
            fi
            ;;
          *)
            log "cardwire mode unreadable, leaving $UNIT alone"
            ;;
        esac
      }

      # $1 = initial|change
      reconcile() {
        local mode
        mode="$(mode_now || true)"
        if [ -z "$mode" ]; then
          log "cardwire mode unreadable, leaving $UNIT alone"
          return 0
        fi
        apply "$mode" "$1"
      }

      watch() {
        local last mode started
        last=""
        while :; do
          mode="$(mode_now || true)"
          if [ -n "$mode" ] && [ "$mode" != "$last" ]; then
            apply "$mode" change
            last="$mode"
          fi
          # Wake on cardwire's Mode property change. POLL is only a safety
          # net in case a notification is missed.
          started=$SECONDS
          while IFS= read -r _; do
            :
          done < <(timeout "$POLL" busctl monitor --json=short \
            --match="type='signal',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',arg0='$IFACE'" 2>/dev/null || true)
          # Guard against a hot loop if the monitor dies straight away.
          if [ $((SECONDS - started)) -lt 5 ]; then
            sleep 2
          fi
        done
      }

      if [ "$#" -eq 0 ]; then
        echo "usage: llamacpp-gpu-coupling --once|--watch" >&2
        exit 2
      fi

      case "$1" in
        --once) reconcile initial ;;
        --watch) watch ;;
        *)
          echo "usage: llamacpp-gpu-coupling --once|--watch" >&2
          exit 2
          ;;
      esac
    '';
  };
in
lib.mkIf
  (
    builtins.elem "laptop" tags && config.services.cardwired.enable && config.services.llama-cpp.enable
  )
  {
    systemd.services.llamacpp-gpu-coupling = {
      description = "Stop llama-cpp while cardwire has the dGPU blocked";
      wantedBy = [ "multi-user.target" ];
      # cardwire settles the mode (including the battery mode) at daemon start,
      # so read it after that; and before llama-cpp starts so the flag below is
      # already in place on a battery boot.
      after = [ "cardwired.service" ];
      before = [ "llama-cpp.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${coupling}/bin/llamacpp-gpu-coupling --once";
        ExecStart = "${coupling}/bin/llamacpp-gpu-coupling --watch";
        Restart = "always";
        RestartSec = 5;
        RuntimeDirectory = "llamacpp-gpu-coupling";
        RuntimeDirectoryMode = "0755";
      };
    };

    # Never load a 20 GB model onto a GPU that is blocked: refuse to start while
    # the coupling has marked the dGPU blocked. Fail-open — no flag (fresh boot,
    # or the coupling stopped) means a normal start.
    systemd.services.llama-cpp.unitConfig.ConditionPathExists =
      "!/run/llamacpp-gpu-coupling/gpu-blocked";
  }

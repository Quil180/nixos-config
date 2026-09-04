#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Nix-native NixOS installer
#
# Installs one of this repository's NixOS configurations onto a bare drive,
# entirely driven by the flake. It replaces the interactive `fresh_install`
# path of install.sh, and is normally run from the installer ISO
# (nixosConfigurations.installer) where the repository is bundled at
# /root/dotfiles. It can also be run from a stock NixOS ISO via:
#
#   nix run github:Quil180/nixos-config#install -- --system snowflake --device /dev/nvme0n1
#
# Unlike the old script there is no checkpointing (the live environment is
# ephemeral); instead every destructive step re-validates before running, and
# storage-bypass mounts are idempotent so a failed run can simply be re-run.
# ---------------------------------------------------------------------------
set -euo pipefail

# Whatever Nix version the environment ships, make flake evaluation work.
export NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../installer
REPO_DIR="$(dirname "$SCRIPT_DIR")"                          # the flake root

# ---------------------------------------------------------------------------
# Config / CLI
# ---------------------------------------------------------------------------
SYSTEM="${NIXOS_INSTALL_SYSTEM:-snowflake}"
USER_="${NIXOS_INSTALL_USER:-quil}"
DEVICE="${NIXOS_INSTALL_DEVICE:-}"
FLAKE="${NIXOS_INSTALL_FLAKE:-$REPO_DIR}"
YES_MODE=0
FORCE=0
SKIP_HOME=0

usage() {
    cat <<'EOF'
Usage: install.sh [OPTIONS]

Installs a NixOS configuration from this flake onto a target drive
(disko partitioning + nixos-install + home-manager activation).

Options:
  --system NAME   NixOS configuration to install   (default: snowflake)
  --user NAME     home-manager user configuration  (default: quil)
  --device DEV    target disk (default: read from system/<name>/disko.nix)
  --flake PATH    flake to install from            (default: this repo)
  --yes           skip interactive prompts (still validates device safety)
  --force         allow reinstall: target /mnt already contains a system
  --skip-home     install system only, skip home-manager activation
  --help          show this help

Environment: NIXOS_INSTALL_SYSTEM / _USER / _DEVICE / _FLAKE
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --system) SYSTEM="${2:?--system needs a value}"; shift 2 ;;
        --user) USER_="${2:?--user needs a value}"; shift 2 ;;
        --device) DEVICE="${2:?--device needs a value}"; shift 2 ;;
        --flake) FLAKE="${2:?--flake needs a value}"; shift 2 ;;
        --yes) YES_MODE=1; shift ;;
        --force) FORCE=1; shift ;;
        --skip-home) SKIP_HOME=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "unknown option: $1"; usage; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Logging / helpers
# ---------------------------------------------------------------------------
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

die() { log_err "$*"; exit 1; }

confirm() { # confirm "prompt" -> true/false
    local prompt="$1" resp
    read -rp "${prompt} (y/N): " resp
    [[ "${resp,,}" =~ ^(yes|y)$ ]]
}

# Run as root (ISO boots to root; stock ISO re-execs via sudo).
if [[ $EUID -ne 0 ]]; then
    if command -v sudo >/dev/null 2>&1; then
        log_info "Re-executing via sudo..."
        exec sudo -E bash "$0" "$@"
    fi
    die "This script must run as root."
fi

for c in nix nixos-install curl lsblk git; do
    command -v "$c" >/dev/null 2>&1 || die "required command '$c' not found"
done

# ---------------------------------------------------------------------------
# Network — check before touching anything destructive
# ---------------------------------------------------------------------------
network_setup() {
    local attempt
    for attempt in 1 2 3; do
        if curl -s --max-time 8 https://cache.nixos.org >/dev/null 2>&1; then
            log_ok "Network is up."
            return 0
        fi
        log_warn "No connectivity (attempt $attempt/3)."
        if (( YES_MODE )); then
            sleep 5; continue
        fi
        if ! command -v nmcli >/dev/null 2>&1; then
            log_err "nmcli not available; connect manually then re-run."
            return 1
        fi
        if confirm "Connect to Wi-Fi now?"; then
            local ssid pass
            read -rp "SSID: " ssid
            read -rsp "Password: " pass; echo
            nmcli device wifi connect "$ssid" password "$pass" \
                && log_ok "Connected to ${ssid}." \
                || log_warn "Wi-Fi connect failed; trying ethernet/etc."
        else
            log_warn "Continuing (will retry connectivity)."
        fi
        sleep 3
    done
    die "Still offline after 3 attempts. Fix networking and re-run the installer."
}

# ---------------------------------------------------------------------------
# Device resolution & safety  (disko.nix is authoritative for what gets wiped)
# ---------------------------------------------------------------------------
DISKO_FILE="${FLAKE}/system/${SYSTEM}/disko.nix"
resolve_device() {
    [[ -f "$DISKO_FILE" ]] || die "no disko config at ${DISKO_FILE} (wrong --system?)"

    # The device disko will actually wipe:
    local disko_dev
    disko_dev="$(sed -nE 's/^\s*device\s*=\s*"(\/dev\/[^"]+)".*/\1/p' "$DISKO_FILE" | head -1)"

    DEVICE="${DEVICE:-$disko_dev}"
    [[ -n "$DEVICE" ]] || die "could not determine target device; pass --device"

    if [[ -n "$disko_dev" && "$disko_dev" != "$DEVICE" ]]; then
        log_warn "${DISKO_FILE} is configured for ${disko_dev}, but you asked for ${DEVICE}."
        (( YES_MODE )) || confirm "Continue anyway?" || die "Aborted by user."
    fi

    [[ -b "$DEVICE" ]] || die "${DEVICE} is not a block device."

    # Refuse if the device (or any partition) is mounted — this also catches
    # the live USB when the ISO was written to the very disk you target.
    if awk -v d="$DEVICE" 'index($1,d)==1 { exit 1 }' /proc/mounts; then
        :
    else
        die "${DEVICE} (or a partition of it) is currently MOUNTED. Unmount it first."
    fi

    local busy
    busy="$(lsblk -rno MOUNTPOINTS "$DEVICE" 2>/dev/null | tr -d ' ' | grep -v '^$' || true)"
    [[ -z "$busy" ]] || die "${DEVICE} is in use (mountpoints: ${busy})."
}

# ---------------------------------------------------------------------------
# Flake sanity check — fail before wiping anything
# ---------------------------------------------------------------------------
flake_check() {
    log_info "Validating flake evaluability for '${SYSTEM}' (${FLAKE})..."
    local out
    if ! out="$(nix eval "${FLAKE}#nixosConfigurations.${SYSTEM}.config.system.build.toplevel.drvPath" 2>&1)"; then
        echo "----- nix eval output -----"
        echo "$out"
        echo "---------------------------"
        die "Flake failed to evaluate for '${SYSTEM}'."
    fi
    log_ok "Flake evaluates cleanly."
}

# ---------------------------------------------------------------------------
# Storage bypass: the live environment's /nix/store is read-only squashfs and
# /tmp is RAM. Redirect build traffic onto the target disk we just mounted.
# Mounts are idempotent so re-runs are safe.
# ---------------------------------------------------------------------------
storage_bypass() {
    if findmnt -n -o FSTYPE /nix/store | grep -q overlay; then
        log_info "Storage bypass already active — skipping."
        return 0
    fi
    log_info "Redirecting build traffic onto the target disk (overlay on /nix/store)..."
    mkdir -p /mnt/tmp
    mount --bind /mnt/tmp /tmp  || log_warn "could not bind /mnt/tmp onto /tmp"
    mkdir -p /mnt/nix-overlay/upper /mnt/nix-overlay/work
    mount -t overlay overlay \
        -o lowerdir=/nix/store,upperdir=/mnt/nix-overlay/upper,workdir=/mnt/nix-overlay/work \
        /nix/store
    systemctl restart nix-daemon || true
    sleep 3
}

# ---------------------------------------------------------------------------
# 1. Disko — partition & mount the target disk at /mnt
# ---------------------------------------------------------------------------
run_disko() {
    log_info "Partitioning ${DEVICE} with disko (${SYSTEM})..."
    if command -v disko >/dev/null 2>&1; then
        disko --mode disko --flake "${FLAKE}#${SYSTEM}"
    else
        nix run "${FLAKE}#disko" -- --mode disko --flake "${FLAKE}#${SYSTEM}"
    fi
    log_ok "Disk partitioning complete — target mounted at /mnt."
}

# ---------------------------------------------------------------------------
# 2. Build + install the system closure
# ---------------------------------------------------------------------------
install_system() {
    log_info "Building NixOS toplevel for '${SYSTEM}' (this is the slow step)..."
    nix build --out-link /root/nixos-toplevel \
        "${FLAKE}#nixosConfigurations.${SYSTEM}.config.system.build.toplevel"
    log_ok "Toplevel built: $(readlink -f /root/nixos-toplevel)"

    # First boot has no passwd yet; agenix provides the hashed passwords at
    # boot — but the age files are encrypted to the *old* host key until the
    # rekey step (see the reminder at the end), so login can only happen via
    # the SSH authorized key from system/<name>/configuration.nix.
    log_info "Installing NixOS to /mnt (nixos-install)..."
    nixos-install --no-root-passwd --root /mnt --system /root/nixos-toplevel
    log_ok "NixOS system installed."
}

# ---------------------------------------------------------------------------
# 3. Copy dotfiles to the new system's home
# ---------------------------------------------------------------------------
copy_dotfiles() {
    local home_dir="/mnt/home/${USER_}"
    log_info "Copying dotfiles to ${home_dir}/.dotfiles..."
    mkdir -p "$home_dir"
    cp -a "${FLAKE}/." "${home_dir}/.dotfiles"
    # The bundled repo has no .git (excluded from flakeSource) — seed a fresh
    # checkout so `git pull` works after first login.
    if ! git -C "${home_dir}/.dotfiles" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git -C "${home_dir}/.dotfiles" init -q
        git -C "${home_dir}/.dotfiles" remote add origin git@github.com:Quil180/nixos-config.git \
            || log_warn "git remote add failed (non-fatal)."
    fi
    # UID 1000 is the first user created by NixOS.
    chown -R 1000:100 "${home_dir}/.dotfiles"
    log_ok "Dotfiles copied."
}

# ---------------------------------------------------------------------------
# 4. Home-manager activation.
#
# Primary: build the activationPackage on the ISO, copy its closure into the
# target store (shared store paths are skipped automatically), then run the
# activation inside the target as the user — offline, no build inside chroot.
# Fallback (network): the old approach, `home-manager switch --flake` inside
# the chroot.
# ---------------------------------------------------------------------------
home_dir="/mnt/home/${USER_}"
HOME_ACT=""

build_home_activation() {
    log_info "Building home-manager activation for '${USER_}'..."
    HOME_ACT="$(nix build --no-link --print-out-paths \
        "${FLAKE}#homeConfigurations.${USER_}.activationPackage")"
    log_ok "Activation package: ${HOME_ACT}"
}

activate_home() {
    [[ -n "$HOME_ACT" ]] || return 1
    [[ -x "${HOME_ACT}/activate" ]] || return 1

    log_info "Copying home closure into the target store..."
    nix copy --to /mnt/nix "$HOME_ACT" || log_warn "nix copy to /mnt/nix failed"

    log_info "Activating home-manager inside the new system (as ${USER_})..."
    # nixos-enter runs the target's activation + resolve everything from the
    # TARGET store, hence the full /nix/var/nix/profiles/system paths.
    if nixos-enter --root /mnt -- /nix/var/nix/profiles/system/sw/bin/sudo -u "${USER_}" \
        env HOME="/home/${USER_}" USER="${USER_}" "${HOME_ACT}/activate"; then
        log_ok "Home-manager activated."
        return 0
    fi
    log_warn "Direct activation failed — falling back to in-chroot home-manager switch."
    return 1
}

home_manager_fallback() {
    local helper="/mnt/tmp/hm-fallback.sh"
    cat > "$helper" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export HOME="/home/${USER_}"
export USER="${USER_}"
cd "\$HOME/.dotfiles"
/nix/var/nix/profiles/system/sw/bin/sudo -u ${USER_} env HOME="\$HOME" USER="${USER_}" \\
    /nix/var/nix/profiles/system/sw/bin/nix run home-manager -- \\
    switch --flake "\$HOME/.dotfiles#${USER_}"
echo "home-manager fallback switch finished (rc=\$?)"
EOF
    chmod +x "$helper"
    log_warn "Running fallback: home-manager switch inside the chroot (needs network)..."
    nixos-enter --root /mnt -- /nix/var/nix/profiles/system/sw/bin/bash /tmp/hm-fallback.sh \
        && log_ok "Fallback home-manager switch finished." \
        || log_warn "Fallback failed too. Run 'home-manager switch --flake ~/.dotfiles#${USER_}' after first login."
    rm -f "$helper" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 5. Cleanup the storage-bypass mounts (they live on the freshly created /
#    subvol and would otherwise be junk on the new system)
# ---------------------------------------------------------------------------
cleanup_bypass() {
    if findmnt -n -o FSTYPE /nix/store | grep -q overlay; then
        umount /nix/store 2>/dev/null || log_warn "could not unmount /nix/store overlay"
    fi
    # Only unmount /tmp if it is our bind (never unmount the live tmpfs).
    if findmnt -n -o SOURCE /tmp | grep -q '/mnt/tmp'; then
        umount /tmp 2>/dev/null || true
    fi
    rm -rf /mnt/tmp /mnt/nix-overlay 2>/dev/null || true
    systemctl restart nix-daemon 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# 6. agenix rekey reminder
# ---------------------------------------------------------------------------
rekey_reminder() {
    local key=""
    key="$(cat /mnt/etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || echo "")"
    echo ""
    log_warn "================ AGENIX REKEY REQUIRED ================"
    log_warn " secrets/*.age are encrypted to the OLD host key. This"
    log_warn " machine just generated a fresh one, so on first boot the"
    log_warn " hashed passwords etc. will FAIL to decrypt until you:"
    echo ""
    if [[ -n "$key" ]]; then
        echo "  1. Replace the host pubkey for '${SYSTEM}' in secrets/secrets.nix with:"
        echo "       ${key}"
    else
        echo "  1. SSH host key not generated yet (may only appear on first boot)."
        echo "     Then update secrets/secrets.nix with the NEW key for '${SYSTEM}'."
    fi
    echo "  2. On this machine or any dev machine with the age identity, run:"
    echo "       cd ${REPO_DIR} && nix run github:ryantm/agenix -- -r -i ~/.ssh/id_ed25519"
    echo ""
    echo "  Until rekeyed, you can still log in via SSH (openssh is enabled and"
    echo "  your pubkey is in system/${SYSTEM}/configuration.nix) but password"
    echo "  logins and other sealed secrets will not work."
    log_warn "======================================================="
    echo ""
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
main() {
    log_info "NixOS installer — system=${SYSTEM} user=${USER_} flake=${FLAKE}"

    network_setup
    resolve_device
    flake_check

    if [[ -e /mnt/etc/NIXOS ]]; then
        if (( FORCE )); then
            log_warn "/mnt already contains a NixOS system — reinstalling (--force)."
        else
            die "/mnt already contains a NixOS system. Pass --force to reinstall."
        fi
    fi

    echo ""
    log_warn "⚠️  About to COMPLETELY ERASE ${DEVICE} (via ${DISKO_FILE})"
    log_warn "    and install '${SYSTEM}' (user '${USER_}')."
    echo ""
    if (( YES_MODE )); then
        log_info "--yes given; proceeding without further confirmation."
    else
        confirm "Are you absolutely sure?" || { log_info "Aborted."; exit 1; }
    fi

    run_disko
    storage_bypass
    install_system
    copy_dotfiles

    if (( SKIP_HOME )); then
        log_warn "--skip-home: home-manager not activated."
    else
        if build_home_activation && activate_home; then
            :
        else
            home_manager_fallback
        fi
    fi

    rekey_reminder
    cleanup_bypass

    echo ""
    log_ok "🎉 Installation of '${SYSTEM}' onto ${DEVICE} complete."
    echo ""
    log_info "Next steps:"
    echo "  1. Reboot into the new system:  reboot"
    echo "  2. First-login alternatives:"
    echo "     - SSH in with your key (hostKeys changed — accept the new one)"
    echo "     - or set a password from the ISO first:   nixos-enter --root /mnt -- passwd ${USER_}"
    echo "  3. Rekey agenix secrets (see reminder above)."
    echo "  4. Optional, once SSH keys work from the new machine:"
    echo "       cd ~/.dotfiles && git submodule update --init --recursive"
    echo ""
}

main "$@"
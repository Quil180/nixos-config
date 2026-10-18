#!/usr/bin/env bash
# nixos-install-drive — install this flake onto a bare machine in one command.
#
# Normally run from the flake-built installer ISO (system/installer/iso.nix),
# where `nixos-install-drive` is on PATH and the flake is bundled at
# /etc/dotfiles. It also works on a stock NixOS live ISO via:
#
#   nix run github:Quil180/nixos-config#install -- --host moraine
#
# Usage:
#   nixos-install-drive --host <host> [--device /dev/nvme0n1] [--key /path/to/id_ed25519] [--yes] [--offline]
#
# What it does, in order:
#   1. network check (curl cache.nixos.org, nmcli fallback)      — skipped with --offline
#   2. locate + verify the agenix user key: --key → ~/.ssh/id_ed25519
#      → first USB partition containing id_ed25519 → paste into terminal
#   3. evaluate the flake for <host> before touching any disk     — skipped with --offline
#   4. refuse a mounted/in-use target disk (this also rules out the
#      USB stick you booted from), show lsblk, ask for confirmation
#   5. disko: wipe + partition + mount the target (destroy,format,mount);
#      you will type the LUKS passphrase here
#   6. redirect /tmp and /nix/store onto the target disk          — skipped with --offline
#      (live ISO RAM workaround; the ISO store is not writable)
#   7. nixos-install --no-root-passwd --no-channel-copy --flake /etc/dotfiles#<host>
#      (offline: --system <prebuilt closure> from the offline ISO)
#   8. place the SSH key at /mnt/home/quil/.ssh/ so agenix decrypts on first boot
#      (the workstation secrets are sealed to this key — no rekey step)
#   9. clone the dotfiles repo with the key → /mnt/home/quil/.dotfiles;
#      falls back to copying the bundled flake
#  10. build (or take prebuilt) homeConfigurations."quil@<host>".activationPackage,
#      nix copy it into the target store and run its /activate as quil
#      (skipped for integratedHome hosts: the home is in the system closure)
#  11. unmount, close LUKS, print next steps (incl. FIDO2 enrollment)

set -euo pipefail

# --- Configuration -----------------------------------------------------------

# Where the flake lives on the live ISO. A stock ISO can point this at a clone.
FLAKE_DIR="${NIXOS_INSTALL_FLAKE:-/etc/dotfiles}"

# `ssh-keygen -y -f <key>` must print this (injected at build time from
# secrets/secrets.nix). When empty, verification is skipped.
EXPECTED_KEY="${NIXOS_INSTALL_EXPECTED_KEY:-}"

DEFAULT_HOST="snowflake"
USER_NAME="quil"
GIT_REMOTE="git@github.com:Quil180/nixos-config.git"
LUKS_NAME="cryptroot"
OFFLINE_TARGETS="/etc/installer/offline-targets"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }

die() { log_error "$*"; exit 1; }

usage() {
  cat <<EOF
Usage: $0 [options]

Install this flake's NixOS + home-manager config onto a bare machine.

Options:
  --host NAME        NixOS configuration to install (default: $DEFAULT_HOST)
  --device /dev/X    Target disk (default: read from disko.nix). Passed to disko.
                     Online only: the offline ISO's disko scripts have the disk baked in.
  --key PATH         Path to ~/.ssh/id_ed25519 of the workstation user (quil@snowflake).
                     The agenix secrets are sealed to this key; without it the
                     fresh system can't decrypt passwords on first boot.
  --yes              Skip confirmations (the mounted-disk safety check still applies)
  --offline          Install without network, from the installer-offline ISO
                     (uses prebuilt closures; skips steps 1, 3 and 6)
  -h, --help         Show this help

The key is otherwise found in this order: ~/.ssh/id_ed25519, /tmp/id_ed25519
(e.g. after scp'ing it in), the first USB partition containing id_ed25519,
or pasted into the terminal (empty line + Enter to finish).

After first boot you may want to enroll FIDO2 for passwordless LUKS unlock:
  systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/luks
EOF
}

# --- Options -----------------------------------------------------------------

HOST=""
DEVICE=""
KEY=""
YES=0
OFFLINE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)  HOST="${2:?--host needs a value}"; shift 2 ;;
    --device) DEVICE="${2:?--device needs a value}"; shift 2 ;;
    --key)   KEY="${2:?--key needs a value}";    shift 2 ;;
    --yes|-y) YES=1; shift ;;
    --offline) OFFLINE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

HOST="${HOST:-$DEFAULT_HOST}"

# The offline ISO carries each host's prebuilt disko script, with the disk
# from its disko.nix baked in; it cannot be retargeted. Refuse up front,
# before anything is touched, rather than wiping a disk the user didn't name.
if [[ $OFFLINE -eq 1 && -n "$DEVICE" ]]; then
  die "--device can't be used with --offline: the prebuilt disko script always targets the disk in system/$HOST/disko.nix. Drop --device, or install online."
fi

command -v ssh-keygen > /dev/null || die "ssh-keygen not found"

# --- Helpers -----------------------------------------------------------------

confirm_yn() {
  local ans
  [[ $YES -eq 1 ]] && return 0
  read -rp "$1 [y/N] " ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

# Read one path by (type, key) from /etc/installer/offline-targets (offline ISO)
offline_path() {
  local type="$1" key="$2"
  awk -v t="$type" -v k="$key" '$1 == t && $2 == k { print $3; exit }' "$OFFLINE_TARGETS" 2>/dev/null
}

# --- Step 1: network ---------------------------------------------------------
network_check() {
  [[ $OFFLINE -eq 1 ]] && { log_info "Offline mode — skipping network check."; return 0; }

  log_info "Checking network connectivity..."
  if curl -fsS --max-time 10 https://cache.nixos.org > /dev/null 2>&1; then
    log_success "Online."
    return 0
  fi
  log_warn "No connectivity detected."

  if command -v nmcli > /dev/null && confirm_yn "Connect to Wi-Fi now?"; then
    local ssid pass
    read -rp "SSID: " ssid
    read -rsp "Wi-Fi password: " pass; echo
    if nmcli device wifi connect "$ssid" password "$pass"; then
      log_success "Wi-Fi connected."
      return 0
    fi
    log_error "Failed to connect. Fix networking manually and re-run."
    exit 1
  fi
  die "No network. Fix connectivity and re-run, or boot the offline ISO and use --offline."
}

# --- Step 2: key -------------------------------------------------------------
# Find the first unmounted removable partition with an id_ed25519 file on it.
find_key_on_usb() {
  local mnt=/mnt/.keyprobe name type dev
  mkdir -p "$mnt"
  while read -r name type; do
    [[ "$type" == "part" ]] || continue
    dev="/dev/$name"
    # Skip anything already mounted (includes the USB the ISO booted from).
    findmnt -rn -S "$dev" > /dev/null 2>&1 && continue
    # Only look at typical removable/loop partitions, not the target nvme.
    case "$name" in
      sd*[0-9] | vd*[0-9] | mmcblk*[0-9]*) ;;
      *) continue ;;
    esac
    if mount -o ro "$dev" "$mnt" 2>/dev/null; then
      if [[ -f "$mnt/id_ed25519" && -s "$mnt/id_ed25519" ]]; then
        cp "$mnt/id_ed25519" /tmp/.nixos-install-key
        umount "$mnt" 2>/dev/null || true
        log_info "Found key on $dev (copied to /tmp)."
        echo /tmp/.nixos-install-key
        return 0
      fi
      umount "$mnt" 2>/dev/null || true
    fi
  done < <(lsblk -rno NAME,TYPE)
  rmdir "$mnt" 2>/dev/null || true
  return 1
}

verify_key() {
  [[ -f "$KEY" ]] || die "Key not found: $KEY"
  local pub
  pub=$(ssh-keygen -y -f "$KEY" 2>/dev/null) || die "Could not read the key $KEY with ssh-keygen — is it a valid private key?"
  # ssh-keygen -y appends the key comment (e.g. "quil@snowflake"); compare
  # only "<type> <base64>", which is what EXPECTED_KEY holds.
  pub=$(awk '{ print $1, $2 }' <<< "$pub")
  if [[ -n "$EXPECTED_KEY" && "$pub" != "$EXPECTED_KEY" ]]; then
    die "Key $KEY does not match the workstation key in secrets/secrets.nix. A wrong key means agenix secrets (incl. passwords) can never decrypt on the new machine. Refusing to continue."
  fi
  log_success "Key verified: ${pub%% *} … (${USER_NAME}@snowflake)"
}

locate_key() {
  # 1. explicit --key flag
  # 2. the ISO user's own key (~/.ssh/id_ed25519)
  # 3. a key scp'ed to /tmp/id_ed25519 (matches the hint below)
  # 4. an id_ed25519 file on a removable USB partition
  # 5. paste the private key into the terminal
  if [[ -z "$KEY" && -f "$HOME/.ssh/id_ed25519" ]]; then
    KEY="$HOME/.ssh/id_ed25519"
    log_info "Using existing key $KEY"
  elif [[ -z "$KEY" && -f "/tmp/id_ed25519" ]]; then
    KEY="/tmp/id_ed25519"
    log_info "Using key from /tmp/id_ed25519 (scp'ed in)"
  elif [[ -z "$KEY" ]]; then
    log_info "Looking for id_ed25519 on removable media..."
    KEY=$(find_key_on_usb || true)
  fi
  if [[ -z "$KEY" ]]; then
    log_warn "No key found — paste the private key below (one long line), then an empty line + Enter:"
    log_warn "  tip: from the dev machine:  scp ~/.ssh/id_ed25519 nixos@<iso-ip>:/tmp/"
    log_warn "  then just run:             nixos-install-drive --key /tmp/id_ed25519"
    cat > /tmp/.nixos-install-key
    KEY=/tmp/.nixos-install-key
  fi
  verify_key
}

# --- Step 3: flake sanity check ----------------------------------------------
flake_check() {
  [[ $OFFLINE -eq 1 ]] && return 0
  log_info "Validating the flake evaluates for host '$HOST'..."
  local names
  names=$(nix eval --json "$FLAKE_DIR#nixosConfigurations" --apply builtins.attrNames 2>&1) \
    || die "flake failed to evaluate from $FLAKE_DIR: $names"
  if ! grep -q "\"$HOST\"" <<< "$names"; then
    die "Host '$HOST' is not a nixosConfiguration of this flake. Available: $names"
  fi
  nix eval "$FLAKE_DIR#nixosConfigurations.$HOST.config.system.build.toplevel.drvPath" > /dev/null 2>&1 \
    || die "flake failed to evaluate the toplevel for '$HOST'. Fix the config before wiping any disk."
  log_success "Flake evaluates cleanly for '$HOST'."
}

# --- Step 4: device safety ----------------------------------------------------
# Resolve the target device: --device wins, else the value baked into the
# host's disko module (re-evaluated online, read from the offline targets file
# offline), else the documented nvme default.
resolve_device() {
  if [[ -n "$DEVICE" ]]; then
    echo "$DEVICE"
  elif [[ $OFFLINE -eq 1 ]]; then
    local d
    d=$(offline_path device "$HOST") || true
    echo "${d:-/dev/nvme0n1}"
  else
    local d
    d=$(nix eval --raw "$FLAKE_DIR#nixosConfigurations.$HOST.config.disko.devices.disk.sdb.device" 2>/dev/null) \
      || d="/dev/nvme0n1"
    echo "$d"
  fi
}

device_safety() {
  TARGET_DEVICE="$(resolve_device)"
  log_info "Target device (from disko config): $TARGET_DEVICE"

  [[ -e "$TARGET_DEVICE" || -L "$TARGET_DEVICE" ]] || die "Device $TARGET_DEVICE does not exist!"
  if findmnt -rn -S "$TARGET_DEVICE" > /dev/null 2>&1; then
    die "Refusing to wipe $TARGET_DEVICE: it is mounted. (This also rules out the USB stick you booted from.)"
  fi

  log_warn "This will COMPLETELY ERASE the disk below:"
  lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS
  echo "  → target: $TARGET_DEVICE (will be erased)"
  confirm_yn "Are you absolutely sure you want to continue?" \
    || die "Cancelled."

  # A dangling symlink that resolves to a mounted disk (e.g. /dev/disk/by-id).
  local real
  real=$(realpath -m "$TARGET_DEVICE" 2>/dev/null) || real="$TARGET_DEVICE"
  if findmnt -rn -S "$real" > /dev/null 2>&1; then
    die "Refusing to wipe $real: it is mounted."
  fi
}

# --- Step 5: disko ------------------------------------------------------------
run_disko() {
  # --device overrides the device baked into the host's disko module; it is
  # threaded through disko's --argstr into the flake's diskoConfigurations.
  local extra=()
  if [[ -n "$DEVICE" ]]; then extra+=(--argstr device "$DEVICE"); fi
  if [[ $YES -eq 1 ]]; then extra+=(--yes-wipe-all-disks); fi

  if [[ $OFFLINE -eq 1 ]]; then
    local disko_script
    disko_script=$(offline_path disko "$HOST")
    [[ -n "$disko_script" ]] || die "No offline disko script for '$HOST' in $OFFLINE_TARGETS"
    # The store path is a package; the script itself is under bin/. It takes
    # only one flag, --yes-wipe-all-disks, as its first argument (--device was
    # already refused for offline installs).
    local bin="$disko_script/bin/disko-destroy-format-mount"
    [[ -x "$bin" ]] || die "Offline disko script missing: $bin"
    local wipe=()
    if [[ $YES -eq 1 ]]; then wipe+=(--yes-wipe-all-disks); fi
    log_info "Running prebuilt disko (offline): $bin"
    log_info "You will be prompted for the LUKS passphrase when the volume is created."
    "$bin" "${wipe[@]}"
  else
    log_info "Partitioning with disko (destroy,format,mount) from $FLAKE_DIR#$HOST"
    log_info "You will be prompted for the LUKS passphrase when the volume is created."
    disko "${extra[@]}" --mode destroy,format,mount --flake "$FLAKE_DIR#$HOST"
  fi
  log_success "Disk partitioned and mounted at /mnt."
}

# --- Step 6: storage workaround ------------------------------------------------
storage_workaround() {
  [[ $OFFLINE -eq 1 ]] && { log_info "Offline mode — no builds happen, skipping the storage overlay."; return 0; }

  # The live ISO keeps /tmp and /nix/store in RAM; building the system and the
  # home-manager generation needs far more. Redirect both onto the target disk.
  if findmnt -rn /nix/store | grep -q "overlay"; then
    log_info "Storage overlay already active."
    return 0
  fi
  log_info "Pointing /tmp and /nix/store at the target disk..."
  mkdir -p /mnt/tmp /mnt/nix-overlay/upper /mnt/nix-overlay/work
  mount --bind /mnt/tmp /tmp
  mount -t overlay overlay -o lowerdir=/nix/store,upperdir=/mnt/nix-overlay/upper,workdir=/mnt/nix-overlay/work /nix/store
  systemctl restart nix-daemon 2>/dev/null || true
  sleep 3
  log_success "Storage workaround in place."
}

# --- Step 7: system install ----------------------------------------------------
install_system() {
  if [[ $OFFLINE -eq 1 ]]; then
    local toplevel
    toplevel=$(offline_path toplevel "$HOST") || die "No offline toplevel for '$HOST' in $OFFLINE_TARGETS"
    log_info "Installing prebuilt system closure: $toplevel"
    nixos-install --no-root-passwd --no-channel-copy --system "$toplevel"
  else
    log_info "Installing NixOS from $FLAKE_DIR#$HOST (this is the slow step)..."
    nixos-install --no-root-passwd --no-channel-copy --flake "$FLAKE_DIR#$HOST"
  fi
  log_success "NixOS system installed."
}

# --- Steps 8-9: key + dotfiles --------------------------------------------------
install_key_and_repo() {
  local target_home="/mnt/home/$USER_NAME"
  local repo_dir="$target_home/.dotfiles"
  local pub_file
  mkdir -p "$target_home/.ssh"

  # The one thing the installer owes you from the beginning of this whole plan:
  # put the user key on the new machine so agenix decrypts on first boot.
  cp "$KEY" "$target_home/.ssh/id_ed25519"
  if [[ -f "$KEY.pub" ]]; then
    cp "$KEY.pub" "$target_home/.ssh/id_ed25519.pub"
  else
    pub_file=$(mktemp)
    ssh-keygen -y -f "$KEY" > "$pub_file"
    cp "$pub_file" "$target_home/.ssh/id_ed25519.pub"
    rm -f "$pub_file"
  fi
  chmod 700 "$target_home/.ssh"
  chmod 600 "$target_home/.ssh/id_ed25519"
  chmod 644 "$target_home/.ssh/id_ed25519.pub"
  chown -R 1000:100 "$target_home" 2>/dev/null || true
  log_success "Key placed at $target_home/.ssh/id_ed25519 (age.identityPaths = /home/quil/.ssh/id_ed25519)."

  export GIT_SSH_COMMAND="ssh -i $KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  if git clone --recurse-submodules "$GIT_REMOTE" "$repo_dir" 2> /tmp/dotfiles-clone.log; then
    log_success "Cloned dotfiles (with wallpapers submodule) into $repo_dir"
  else
    log_warn "git clone failed ($(tail -n1 /tmp/dotfiles-clone.log)); copying the bundled flake instead."
    cp -a "$FLAKE_DIR" "$repo_dir"
    rm -rf "$repo_dir/.git"
    git -C "$repo_dir" init -q
    git -C "$repo_dir" remote add origin "$GIT_REMOTE"
    log_warn "Submodules (wallpapers) are missing — run 'git submodule update --init --recursive' after first login."
  fi
  chown -R 1000:100 "$target_home" 2>/dev/null || true
}

# --- Step 10: home-manager ------------------------------------------------------
install_home() {
  local act
  local uri="$FLAKE_DIR#homeConfigurations.\"$USER_NAME@$HOST\".activationPackage"

  # Hosts with integratedHome have no standalone target: their home is part
  # of the system closure and home-manager-$USER_NAME.service activates it on
  # first boot. The offline targets list omits their `home` line likewise.
  if [[ $OFFLINE -eq 1 ]]; then
    act=$(offline_path home "$USER_NAME@$HOST")
    if [[ -z "$act" ]]; then
      log_info "No standalone home for '$USER_NAME@$HOST' — it is built into the system and activates on first boot."
      return 0
    fi
    log_info "Using prebuilt home-manager activationPackage: $act"
  else
    if [[ $(cd "$FLAKE_DIR" && nix eval .#homeConfigurations --apply "h: h ? \"$USER_NAME@$HOST\"" 2>/dev/null) != "true" ]]; then
      log_info "No standalone home for '$USER_NAME@$HOST' — it is built into the system and activates on first boot."
      return 0
    fi
    log_info "Building $uri ..."
    # --no-link so we never depend on cwd; the store path is what we copy over.
    act=$(cd "$FLAKE_DIR" && nix build --no-link --print-out-paths "$uri" 2> /tmp/home-build.log) \
      || { log_warn "Building the home-manager generation failed ($(tail -n3 /tmp/home-build.log))"; return 1; }
  fi

  log_info "Copying the home-manager closure into the target store..."
  nix copy --to /mnt "$act" 2> /tmp/nix-copy.log \
    || { log_warn "nix copy failed ($(tail -n3 /tmp/nix-copy.log))"; return 1; }

  log_info "Activating the home-manager generation as $USER_NAME (inside the new system)..."
  # Storage workaround note: activating from the freshly copied store path means
  # no nix evaluation is involved on the target — the fragile part is gone.
  nixos-enter --root /mnt -- su "$USER_NAME" -lc "$act/activate" 2> /tmp/home-activate.log \
    || { log_warn "Activation had issues ($(tail -n5 /tmp/home-activate.log)) — run 'home-manager switch' after first login."; }
  log_success "Home-manager generation installed."
}

# --- Step 11: finish -------------------------------------------------------------
finish() {
  log_info "Unmounting and closing LUKS..."
  umount /tmp 2>/dev/null || true            # the bind mount, if any
  umount /nix/store 2>/dev/null || true      # the overlay, if any
  umount -R /mnt > /dev/null 2>&1 || true
  cryptsetup luksClose "$LUKS_NAME" 2>/dev/null || true
  log_success "Done — you can now reboot."
  echo
  echo ""
  echo "  Next steps:"
  echo "   1. sudo reboot"
  echo "   2. Log in as '$USER_NAME' — the password comes from agenix (quil_password.age),"
  echo "      decrypted on first boot with your key at /home/$USER_NAME/.ssh/id_ed25519."
  echo "      NO rekey step is needed for the workstations."
  echo "   3. The dotfiles are at /home/$USER_NAME/.dotfiles (clone of $GIT_REMOTE)."
  echo ""
  echo "  Optional, after first boot — enroll FIDO2 for passwordless LUKS unlock:"
  echo "     systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/luks"
  echo "     (the crypttab already has fido2-device=auto + token-timeout=10)"
  echo ""
}

# --- Main -----------------------------------------------------------------------
[[ $EUID -ne 0 ]] && exec sudo -E "$0" "$@"

if [[ $OFFLINE -eq 1 && ! -f "$OFFLINE_TARGETS" ]]; then
  die "--offline requires the offline ISO (installer-offline): $OFFLINE_TARGETS is missing."
fi

log_info "Installer for host '$HOST' (device: ${DEVICE:-auto}, offline: $([ $OFFLINE -eq 1 ] && echo yes || echo no))"

network_check
locate_key
flake_check
device_safety
run_disko
storage_workaround
install_system
install_key_and_repo
install_home || log_warn "home-manager step failed — see notes above."
finish
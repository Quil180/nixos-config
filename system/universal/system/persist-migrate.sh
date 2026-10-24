#!/usr/bin/env bash
# persist-migrate — copy a running machine's live state into /persist, once,
# before its first boot with impermanence on.
#
# Turning `persist` on for a machine that already has data is the dangerous
# moment: on that boot, every persisted path gets an (empty) /persist folder
# bind-mounted over it, and `/` itself is wiped. Without this copy, ~/Documents,
# ~/.ssh, Wi-Fi, host keys, … all look gone. This script copies exactly the
# paths the configuration will persist, read from the flake itself.
#
# Usage, in this order:
#   1. Enable persistence in the config: uncomment `persist` in
#      system/<host>/configuration.nix and in users/quil/home.nix.
#   2. sudo nixos-rebuild boot --flake ~/.dotfiles
#        `boot`, NOT `switch` (and not `upds`): switch would mount the empty
#        /persist folders over your data right away.
#   3. Close apps that write their state (browser, Discord, Steam, editors);
#      logging out to a TTY is best.
#   4. nix run ~/.dotfiles#persist-migrate            (shows the plan, asks)
#   5. Reboot straight away; anything changed after step 4 isn't copied.
#
# It never deletes or modifies the live data: it only creates and writes under
# /persist. Copies are btrfs reflinks when / /home and /persist share a
# filesystem (snowflake/moraine), so they are instant and take no extra space.
#
# Options:
#   --host NAME     nixosConfiguration to read (default: this machine's hostname)
#   --flake DIR     the dotfiles flake (default: ~/.dotfiles)
#   --dry-run       print the plan and exit (no sudo needed; sizes of
#                   root-only folders may then be incomplete)
#   --refresh       also copy into /persist folders that already have data
#                   (live files overwrite same-named ones; nothing is deleted)
#   --yes           don't ask for confirmation

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; BLUE=$'\033[0;34m'; NC=$'\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $*" >&2; }
die() { log_error "$*"; exit 1; }

usage() { sed -n '/^# persist-migrate —/,/^set -euo/{/^set -euo/d;s/^# \{0,1\}//;p}' "$0"; }

HOST=""
FLAKE=""
DRY_RUN=0
REFRESH=0
YES=0
PLAN=""
WIPE_HOME=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)    HOST="${2:?--host needs a value}"; shift 2 ;;
    --flake)   FLAKE="${2:?--flake needs a value}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --refresh) REFRESH=1; shift ;;
    --yes|-y)  YES=1; shift ;;
    --plan)    PLAN="${2:?}"; shift 2 ;; # internal: the root half of the run
    --wipe-home) WIPE_HOME=1; shift ;;   # internal: the host sets persist.wipeHome
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

HOST="${HOST:-$(hostname)}"
FLAKE="${FLAKE:-$HOME/.dotfiles}"

# --- Plan: evaluate what the configuration persists (as the user) ------------
# One JSON object per persisted path: {kind, live, dest, user, group, mode}.
# dest is impermanence's own rule: persistentStoragePath + the absolute path.
# Covers the system lists, integrated home-manager users, and a standalone
# "<user>@<host>" home target if the flake has one.
ENTRIES_NIX='
  roots: builtins.concatMap (r:
    map (d: {
      kind = "dir"; live = d.dirPath; dest = d.persistentStoragePath + d.dirPath;
      inherit (d) user group mode;
    }) r.directories
    ++ map (f: {
      kind = "file"; live = f.filePath; dest = f.persistentStoragePath + f.filePath;
      user = null; group = null; mode = null;
    }) r.files
  ) (builtins.filter (r: r.enable) (builtins.attrValues roots))'

make_plan() {
  local out="$1" sys home
  log_info "Evaluating what '$HOST' persists (from $FLAKE)..."
  sys=$(nix eval --json "$FLAKE#nixosConfigurations.\"$HOST\".config" --apply "
    cfg: let entries = $ENTRIES_NIX; in
    entries (cfg.environment.persistence or { })
    ++ builtins.concatMap (u: entries (u.home.persistence or { }))
      (builtins.attrValues (cfg.home-manager.users or { }))") \
    || die "Could not evaluate nixosConfigurations.$HOST in $FLAKE."
  home=$(nix eval --json "$FLAKE#homeConfigurations" --apply "
    hs: let entries = $ENTRIES_NIX; t = \"$USER@$HOST\"; in
    if hs ? \${t} then entries (hs.\${t}.config.home.persistence or { }) else [ ]" 2>/dev/null) \
    || home='[]'
  jq -s 'add | unique_by(.live)' <<< "$sys $home" > "$out"
  [[ $(jq length "$out") -gt 0 ]] \
    || die "'$HOST' persists nothing in $FLAKE. Enable \`persist\` in the config first (step 1 in --help)."
  [[ $(nix eval "$FLAKE#nixosConfigurations.\"$HOST\".config" \
    --apply 'cfg: cfg.persist.wipeHome or false' 2>/dev/null) == true ]] && WIPE_HOME=1
  return 0
}

if [[ -z "$PLAN" ]]; then
  [[ $EUID -ne 0 ]] || die "Run this as your normal user (it evaluates your flake, then asks for sudo)."
  PLAN=$(mktemp --suffix=.persist-plan.json)
  make_plan "$PLAN"
  args=(--plan "$PLAN" --host "$HOST" --flake "$FLAKE")
  [[ $REFRESH -eq 1 ]] && args+=(--refresh)
  [[ $YES -eq 1 ]] && args+=(--yes)
  [[ $WIPE_HOME -eq 1 ]] && args+=(--wipe-home)
  # A dry run only reads, so it stays unprivileged.
  [[ $DRY_RUN -eq 1 ]] || exec sudo -- "$0" "${args[@]}"
fi

# --- From here on: root (or a dry run), with the plan in $PLAN ----------------
[[ $EUID -eq 0 || $DRY_RUN -eq 1 ]] || die "internal: the copy phase must run as root."
[[ -s "$PLAN" ]] || die "internal: plan file $PLAN is missing."

# Decide each entry's action before touching anything, so the plan shown is
# exactly what runs.
declare -a ACTIONS=()  # "copy|<kind>|<live>|<dest>" or "skip|<kind>|<live>|<reason>"
plan_entry() {
  local kind="$1" live="$2" dest="$3"
  if [[ -L "$live" ]]; then
    ACTIONS+=("skip|$kind|$live|a symlink, recreated by whatever manages it")
  elif [[ ! -e "$live" ]]; then
    ACTIONS+=("skip|$kind|$live|doesn't exist yet; created empty at boot")
  elif [[ "$kind" == dir ]] && mountpoint -q "$live"; then
    ACTIONS+=("skip|$kind|$live|already a mount: persistence is active here")
  elif [[ "$kind" == file ]] && findmnt -rn --mountpoint "$live" > /dev/null; then
    ACTIONS+=("skip|$kind|$live|already a mount: persistence is active here")
  elif [[ "$kind" == dir && -d "$dest" && -n "$(ls -A "$dest")" && $REFRESH -eq 0 ]]; then
    ACTIONS+=("skip|$kind|$live|$dest already has data (use --refresh to copy again)")
  elif [[ "$kind" == file && -e "$dest" && $REFRESH -eq 0 ]]; then
    ACTIONS+=("skip|$kind|$live|$dest already exists (use --refresh to copy again)")
  else
    ACTIONS+=("copy|$kind|$live|$dest")
  fi
}

mountpoint -q /persist || die "/persist is not mounted. Is this host's disk layout the one with a persist subvolume?"

while IFS=$'\t' read -r kind live dest; do
  plan_entry "$kind" "$live" "$dest"
done < <(jq -r '.[] | [.kind, .live, .dest] | @tsv' "$PLAN")

ncopy=0
echo
log_info "Plan for '$HOST':"
for a in "${ACTIONS[@]}"; do
  IFS='|' read -r what kind live rest <<< "$a"
  if [[ "$what" == copy ]]; then
    ncopy=$((ncopy + 1))
    size=$(du -sh "$live" 2>/dev/null | cut -f1 || true)
    printf '  %scopy%s  %-4s %-55s → %s (%s)\n' "$GREEN" "$NC" "$kind" "$live" "$rest" "$size"
  else
    printf '  %sskip%s  %-4s %-55s %s\n' "$YELLOW" "$NC" "$kind" "$live" "$rest"
  fi
done
echo

[[ $DRY_RUN -eq 1 ]] && { log_info "Dry run: nothing copied."; exit 0; }
[[ $ncopy -gt 0 ]] || { log_success "Nothing to copy."; exit 0; }

if [[ $YES -eq 0 ]]; then
  read -rp "Copy these $ncopy paths into /persist? [y/N] " ans
  [[ "${ans,,}" == y || "${ans,,}" == yes ]] || die "Cancelled; nothing copied."
fi

# Create dest's missing parents with the owner and mode of the live parents,
# so e.g. /persist/home/quil/.config belongs to quil like ~/.config does.
make_parents() {
  local live="$1" dest="$2" prefix part sub=""
  prefix="${dest%"$live"}"
  # The persistent root itself (e.g. /persist/system) may not exist yet;
  # impermanence would create it root-owned, 0755.
  [[ -d "$prefix" ]] || install -d -m 0755 -o root -g root "$prefix"
  IFS='/' read -ra parts <<< "$(dirname "$live")"
  for part in "${parts[@]}"; do
    [[ -n "$part" ]] || continue
    sub="$sub/$part"
    if [[ ! -d "$prefix$sub" ]]; then
      mkdir "$prefix$sub"
      chown --reference="$sub" "$prefix$sub"
      chmod --reference="$sub" "$prefix$sub"
    fi
  done
}

count() { find "$1" 2>/dev/null | wc -l; }

failed=0
mismatched=0
for a in "${ACTIONS[@]}"; do
  IFS='|' read -r what kind live dest <<< "$a"
  [[ "$what" == copy ]] || continue
  make_parents "$live" "$dest"
  if [[ "$kind" == dir ]]; then
    if [[ -d "$dest" ]]; then
      cp -a --reflink=auto "$live/." "$dest/" || { log_error "copy failed: $live"; failed=$((failed + 1)); continue; }
    else
      cp -a --reflink=auto "$live" "$dest" || { log_error "copy failed: $live"; failed=$((failed + 1)); continue; }
    fi
    # Live dirs can change during the copy (logs, caches); a count mismatch is
    # a warning to look at, not a failure.
    if [[ $(count "$live") -ne $(count "$dest") ]]; then
      log_warn "$live: $(count "$live") entries live, $(count "$dest") in $dest (it may have changed while copying)"
      mismatched=$((mismatched + 1))
    fi
  else
    cp -a --reflink=auto "$live" "$dest" || { log_error "copy failed: $live"; failed=$((failed + 1)); continue; }
    cmp -s "$live" "$dest" || { log_warn "$live differs from $dest after copying"; mismatched=$((mismatched + 1)); }
  fi
  log_success "$live"
done

echo
if [[ $failed -gt 0 ]]; then
  die "$failed copies failed (see above). Fix them and re-run with --refresh before rebooting."
fi
[[ $mismatched -gt 0 ]] && log_warn "$mismatched paths changed while copying; re-run with --refresh after closing what writes to them."
log_success "Copied $ncopy paths into /persist."
if [[ $WIPE_HOME -eq 1 ]]; then
  old_home="the old /home is kept in old_homes for 30 days too (persist.wipeHome)"
else
  old_home="the old home folders are still on disk underneath the new mounts"
fi
cat <<EOF

  Next: reboot now (the generation from 'nixos-rebuild boot' is the default).
  Changes made after this point are not in /persist.

  After the reboot, check your files are there. The originals are untouched:
  the old / is kept in old_roots for 30 days, and $old_home.
EOF

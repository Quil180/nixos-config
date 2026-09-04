# NixOS Configuration

A Nix flake ("Dendritic Pattern") managing NixOS systems and home-manager
users. The star feature: **a flake-built installer ISO** that installs the
entire configuration onto a bare machine from one command.

- Systems: `snowflake` (see `system/<host>/`)
- Users (home-manager): `quil` (see `users/<user>/`)
- Secrets: agenix (`secrets/*.age`)

---

## 1. Install a fresh machine (the installer ISO)

### Prerequisites

- A machine with **Nix + flakes** to build the ISO (any Linux box, or even
  this one). Everything is pinned by `flake.lock`.
- A **USB stick** (≥ 1 GB; the ISO is ~560 MB).
- The target machine with **UEFI**, and **network access** during install
  (builds pull from cache.nixos.org).
- First login relies on an SSH key already authorized in
  `system/<host>/configuration.nix` (see §2) — e.g. `id_snowflake.pub`.

### 1a. Build the ISO

```bash
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

The ISO lands at `result/iso/nixos-*-x86_64-linux.iso`.

**Or let CI build & publish it**: on the **Actions → CI** page, press
“Run workflow” (optionally set a `release_tag`, `release_notes`, and/or
`draft`). It builds the ISO and, because it's a manual run, uploads it as
a **GitHub release** (`installer-<date>-<time>` tag) together with a
`SHA256SUMS` checksum file. You can then download the ISO directly from
the release page and flash it (§1b).

It contains:

- your whole repository (minus `.git`) at `/root/dotfiles`,
- `disko`, `nixos-install`, `nixos-enter`, `nmcli`, `git`, `curl`,
- the `nixos-install-drive` command, a root login shell, and a banner telling
  you exactly what to do.

### 1b. Flash the USB

```bash
lsblk                      # identify your USB stick (e.g. /dev/sda)
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

⚠️ **Do not target the disk you want to install onto.** The installer safety
check refuses to wipe a disk that is mounted — which would include the very
USB you just booted from.

### 1c. Boot and install

Boot the USB on the target machine (UEFI), let the automatic root login run,
then:

```
nixos-install-drive
```

You'll get a live walkthrough:

1. **network check** — must reach cache.nixos.org; `nmcli` offers Wi-Fi setup.
2. **device safety** — shows exactly which disk will be erased (parsed from
   `system/<host>/disko.nix`), refuses if it's mounted/in use.
3. **flake eval check** — your configuration must evaluate before anything
   destructive happens.
4. **disko** — partitions & mounts `/mnt` (the layout in
   `system/<host>/disko.nix`).
5. **system build + install** — the slow step; then `nixos-install`.
6. **home-manager** — prebuilt on the ISO, copied into the target store, and
   activated inside the new system.
7. **rekey reminder** — agenix secrets are sealed to the *old* host key; this
   step tells you what to do (see §4).
8. Done — reboot.

Options (all optional, defaults come from `installer/iso.nix`):

```
nixos-install-drive --system snowflake --user quil --device /dev/nvme0n1
nixos-install-drive --yes                     # skip confirmations
nixos-install-drive --force                   # reinstall over an existing system
nixos-install-drive --skip-home               # system only
nixos-install-drive --help
```

**Unattended install** (automation): set `installer.autoStart = true` in
`installer/iso.nix`, rebuild the ISO, boot; it wipes and installs by itself.

**Without building an ISO**: a plain NixOS ISO can install straight from
GitHub:

```bash
nix run github:Quil180/nixos-config#install -- \
  --system snowflake --user quil --device /dev/nvme0n1
```

### 1d. Change what the ISO installs by default

In `installer/iso.nix`:

```nix
installer.system   = "snowflake";   # NixOS config (system/<name>/disko.nix)
installer.user     = "quil";        # home-manager user (users/<user>/)
installer.device   = "/dev/nvme0n1";# informational; disko.nix is authoritative
installer.autoStart = false;        # true = unattended install at boot
```

---

## 2. First boot

- Log in via **SSH** using the pubkey already authorized in
  `system/<host>/configuration.nix` (SSH host keys changed — accept the new
  ones). There is **no password** yet (`--no-root-passwd`), and the agenix
  password secrets can't decrypt until the rekey in §4.
- Or set a password from the installer before rebooting:
  `nixos-enter --root /mnt -- passwd quil`

---

## 3. First login housekeeping

```bash
# Update the flake pins (optional)
cd ~/.dotfiles && nix flake update

# Fetch the wallpapers submodule (129 MB, not bundled in the ISO)
git submodule update --init --recursive

# In case home-manager activation didn't fully apply:
home-manager switch --flake ~/.dotfiles#quil
```

The copied checkout has no `.git` (excluded from the ISO bundle) — it's
seeded with `git init` + the `origin` remote, so `git pull` works once SSH
keys are set up on the machine.

---

## 4. Rekey agenix secrets (important!)

`secrets/*.age` are encrypted to the host pubkeys in `secrets/secrets.nix`.
A freshly installed machine has a **brand-new SSH host key**, so secrets will
fail to decrypt until re-encrypted.

From any machine that has your age identity (your dev machine, or the new
box once your SSH key works):

```bash
# 1. Replace the host key for 'snowflake' in secrets/secrets.nix with the
#    machine's real key (cat /etc/ssh/ssh_host_ed25519_key.pub on the box).
# 2. Re-encrypt:
cd ~/.dotfiles
nix run github:ryantm/agenix -- -r -i ~/.ssh/id_ed25519
# or, if agenix is already on PATH:  agenix --rekey -i ~/.ssh/id_ed25519
# (RULES defaults to ./secrets.nix; -i points at your private SSH key)
```

Until rekeyed: SSH login works (keys are in the NixOS config), but password
logins and other sealed secrets may fail.

---

## 5. Daily operation

```bash
# Update the flake inputs (all of them, or targeted)
nix flake update

# Rebuild the system (after cloning on a new machine)
sudo nixos-rebuild switch --flake .#snowflake

# Rebuild home-manager
home-manager switch --flake .#quil
```

---

## 6. Layout / troubleshooting

```
flake.nix                flake-parts; flake = nixosConfigurations + homeConfigurations
installer/
  iso.nix                the installer ISO config (options installer.*)
  install.sh             the orchestrator (what nixos-install-drive runs)
  README.md              installer-specific reference
system/<host>/           per-machine modules; disko.nix = disk layout (AUTH
                         for what gets wiped!), hardware-configuration.nix
users/<user>/            home-manager modules
secrets/                 agenix .age files + secrets.nix (host pubkeys)
```

Troubleshooting:

| Symptom | Fix |
|---|---|
| Install fails at the network check | Connect via `nmcli device wifi connect ...` or ethernet, re-run — everything is safe before the wipe |
| `nixos-install-drive` refuses: "device is mounted" | You pointed it at the live USB; pick the real disk |
| Installed system boots but no password works | Secrets not rekeyed yet → §4, or set a password with `nixos-enter --root /mnt -- passwd <user>` from the installer |
| Wallpaper dir empty | `git submodule update --init --recursive` (needs SSH keys) |
| Reinstall over an existing system | `nixos-install-drive --force` |
| disk layout wrong | Edit `system/<host>/disko.nix`, then rebuild the ISO |

The installer is strictly safe by default: it refuses mounted disks, refuses
to proceed if the flake doesn't evaluate, validates the device against
`disko.nix`, and requires an explicit `--yes` or confirmation for the wipe.
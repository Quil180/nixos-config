# NixOS Configuration

A Nix flake ("Dendritic Pattern") managing NixOS systems and home-manager
users. The star feature: **a flake-built installer ISO** that installs the
entire configuration onto a bare machine from one command.

- Systems: `snowflake` (laptop) and `moraine` (desktop) — see `system/<host>/`
- Users (home-manager): one target per host, `quil@snowflake` / `quil@moraine`
  (see `users/<user>/`)
- Secrets: agenix (`secrets/*.age`), sealed to your user key — see §4

---

## 1. Install a fresh machine (the installer ISO)

### Prerequisites

- A machine with **Nix + flakes** to build the ISO (any Linux box, or even
  this one). Everything is pinned by `flake.lock`.
- A **USB stick**: a few GB for the online ISO, ≥ 16 GB for the offline
  variant (it bundles both personal machines' closures, 10–20 GB).
- The target machine with **UEFI**, and **network access** during install
  (the online variant builds from cache.nixos.org).
- Your workstation key **`~/.ssh/id_ed25519`** — the agenix secrets
  (`quil_password`, `root_password`, `git_identity`, …) are sealed to this
  key (it's the `user_quil` entry in `secrets/secrets.nix`). The installer
  verifies `--key` against it and places the key on the fresh system, so
  first boot decrypts everything with **no rekey step** (§2).

### 1a. Build the ISO

```bash
nix build .#iso          # online ISO (~1–2 GB): installs any host
# or
nix build .#iso-offline  # offline ISO: prebuilt snowflake + moraine closures
```

(`iso` is an alias for `nixosConfigurations.installer.config.system.build.isoImage`.)

The ISO lands at `result/iso/nixos-*-x86_64-linux.iso`. It contains:

- your whole repository (minus `.git`, wallpapers, editor cruft) at
  `/etc/dotfiles`,
- `disko`, `nixos-install`, `nixos-enter`, `nmcli`, `git`, `curl`,
- the `nixos-install-drive` command, sshd (root + nixos accept
  `system/keys/id_snowflake.pub`), and a banner telling you exactly what to
  do.

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
nixos-install-drive --host snowflake
```

You'll get a live walkthrough (11 steps):

1. **network check** — must reach cache.nixos.org; `nmcli` offers Wi-Fi setup.
2. **key** — locate + verify the agenix user key: `--key` → `~/.ssh/id_ed25519`
   → first USB partition containing `id_ed25519` → paste into the terminal.
   The public half must match `user_quil` in `secrets/secrets.nix`.
3. **flake eval check** — your configuration must evaluate before anything
   destructive happens.
4. **device safety** — shows exactly which disk will be erased (the device in
   `system/<host>/disko.nix`, or `--device`), refuses if it's mounted/in use.
5. **disko** — wipe + partition + mount the target (destroy,format,mount);
   you type the LUKS passphrase here.
6. **storage workaround** — redirects `/tmp` and `/nix/store` onto the target
   disk (live-ISO RAM workaround; the ISO store isn't writable).
7. **system install** — `nixos-install --no-root-passwd --flake ...#<host>`
   (offline: installs the prebuilt closure instead — no network, no build).
8. **key on target** — the verified key lands at
   `/mnt/home/quil/.ssh/id_ed25519` so agenix decrypts on first boot.
9. **dotfiles** — `git clone` of the repo → `/mnt/home/quil/.dotfiles`
   (falls back to copying the bundled flake if the clone fails).
10. **home-manager** — builds `homeConfigurations."quil@<host>".activationPackage`,
    `nix copy`s it into the target store, and activates it as `quil`.
11. **finish** — unmount, close LUKS, print next steps (SSH key, FIDO2 hint).

Options (all optional; the default host is `snowflake`):

```
nixos-install-drive --host moraine --device /dev/nvme0n1
nixos-install-drive --key /path/to/id_ed25519   # skip auto-discovery
nixos-install-drive --yes                        # skip confirmations
nixos-install-drive --offline                    # from the offline ISO, no network
nixos-install-drive --help
```

> `--offline` uses the prebuilt closures + `offline_path` lookup table
> (`/etc/installer/offline-targets`) and skips steps 1, 3 and 6.

**Without building an ISO**: from a stock NixOS live ISO, clone the repo and
point the script at it:

```bash
git clone git@github.com:Quil180/nixos-config /tmp/dotfiles
NIXOS_INSTALL_FLAKE=/tmp/dotfiles nix run github:Quil180/nixos-config#install -- \
  --host snowflake
```

### 1d. What the ISO installs by default

- Default host: `DEFAULT_HOST="snowflake"` in
  `system/installer/nixos-install-drive.sh`.
- Default device: read from the host's `disko.nix`; `--device` overrides it
  via the flake's per-host `diskoConfigurations`.
- Offline hosts: `offlineHosts = [ "snowflake" "moraine" ]` in `flake.nix`.

---

## 2. First boot

- Log in via **SSH** with your workstation login key — its public half
  (`system/keys/id_snowflake.pub`) is authorized for `quil` in the NixOS
  config (`workstation.nix`), so sshd accepts it on first boot.
- The user password comes from the agenix secret `quil_password.age`,
  decrypted with the **`id_ed25519`** key the installer placed at
  `/home/quil/.ssh/` (it must match `user_quil` in `secrets/secrets.nix`).
  **Workstations need no rekey** — their secrets are sealed to your user
  key, not the machine's host key.
- Optional after first boot — enroll FIDO2 for passwordless LUKS unlock:
  ```
  systemd-cryptenroll --fido2-device=auto /dev/disk/by-partlabel/luks
  ```
  (the crypttab already has `fido2-device=auto` + `token-timeout=10`)

---

## 3. First login housekeeping

```bash
# Fetch the wallpapers submodule (129 MB, not bundled in the ISO)
cd ~/.dotfiles && git submodule update --init --recursive

# In case home-manager activation didn't fully apply:
home-manager switch --flake ~/.dotfiles#quil@snowflake

# Update the flake pins (optional)
nix flake update
```

`~/.dotfiles` is a real git clone of the repo (or a copy of the bundled
flake if the clone failed mid-install — then `git init` + add the `origin`
remote, and `git pull` works once SSH keys are set up).

---

## 4. Secrets model (agenix)

`secrets/*.age` files are sealed to the recipients in `secrets/secrets.nix`:

- **Workstation secrets** (`quil_password`, `root_password`, `git_identity`,
  `snowflake`, …) are sealed to **`user_quil`** — your key. The installer
  places that key on the fresh machine (§1c step 8), so decryption works out
  of the box. Nothing to do.
- **Server secrets** use a host-key model: sealed to `user_quil` plus the
  server's `/etc/ssh/ssh_host_ed25519_key.pub`. When a server is first set
  up: paste its host key into `hosts` in `secrets/secrets.nix`, then rekey
  from the `secrets/` directory:
  ```bash
  nix run github:ryantm/agenix -- -r -i ~/.ssh/id_ed25519
  ```

---

## 5. Daily operation

```bash
# Update the flake inputs (all of them, or targeted)
nix flake update

# Rebuild the system (after cloning on a new machine)
sudo nixos-rebuild switch --flake .#snowflake

# Rebuild home-manager
home-manager switch --flake .#quil@snowflake
```

---

## 6. Layout / troubleshooting

```
flake.nix                  flake-parts; flake = nixosConfigurations + homeConfigurations
system/<host>/             per-machine modules; disko.nix = disk layout (AUTH
                           for what gets wiped!), hardware-configuration.nix
system/installer/
  iso.nix                  registers the `installer` NixOS host (the online ISO)
  nixos-install-drive.sh   the 11-step installer (--help for options)
system/universal/          shared modules across hosts (workstation, persist, …)
lib/
  installer-module.nix     shared ISO module body (online/offline differ only in
                           the preloaded closures)
  install-script.nix       packages `nixos-install-drive` (also `nix run .#install`)
install.sh                 maintenance menu (rebuild system/home, update flake);
                           fresh installs are `nixos-install-drive`'s job
users/<user>/              home-manager modules
secrets/                   agenix .age files + secrets.nix (recipient keys)
```

Troubleshooting:

| Symptom | Fix |
|---|---|
| Install fails at the network check | Connect via `nmcli device wifi connect ...` or ethernet, re-run — everything is safe before the wipe |
| `nixos-install-drive` refuses: "device is mounted" | You pointed it at the live USB; pick the real disk |
| Installed system boots but the password doesn't work | The agenix `quil_password` secret didn't decrypt — did the installer place your key at `/home/quil/.ssh/id_ed25519`? (that key must match `user_quil` in `secrets/secrets.nix`) |
| Wallpaper dir empty | `git submodule update --init --recursive` (needs SSH keys) |
| disk layout wrong | Edit `system/<host>/disko.nix`, rebuild the ISO (`.#iso`), rerun |

The installer is strictly safe by default: it refuses mounted disks, refuses
to proceed if the flake doesn't evaluate, verifies the agenix key before
touching anything, and requires an explicit `--yes` or confirmation for the
wipe.
# Nix-native installer

Replaces the hand-rolled `install.sh` orchestrator with a flake-driven
installer: you get your own, tailored installer ISO that knows your
configuration, and installs it onto a bare disk from one command.

## Flow

```
nix build .#nixosConfigurations.installer.config.system.build.isoImage
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Boot the USB, accept the new root shell, and run:

```
nixos-install-drive
```

That partitions the disk with **disko** (`system/<host>/disko.nix`), installs
NixOS via `nixos-install`, copies the dotfiles into the new home, and
activates **home-manager** (built on the ISO, copied into the target store —
no build needed inside the chroot). Edit the installer's defaults in
`installer/iso.nix` (`installer.system`, `installer.user`,
`installer.device`) or pass flags:

```
nixos-install-drive --system snowflake --user quil --device /dev/nvme0n1
```

Unattended (for auto-provisioning): set `installer.autoStart = true` and the
ISO wipes and installs by itself at boot (`--yes`).

## Without building an ISO (stock NixOS ISO)

The same installer script is a flake app, so on a plain NixOS ISO you can:

```
nix run github:Quil180/nixos-config#install -- \
  --system snowflake --user quil --device /dev/nvme0n1
```

It downloads the flake, validates, and runs the same pipeline. (You need
`nixos-install`, `disko` gets pulled from the flake.)

## What happens, step by step

1. **network check** — must reach cache.nixos.org (builds); nmcli fallback.
2. **device safety** — the script parses the real target device out
   of `system/<host>/disko.nix`, refuses mounted disks (this also catches the
   live USB), and requires a confirmation unless `--yes`.
3. **flake eval check** — before anything destructive, the target
   configuration must evaluate.
4. **disko** — partitions/mounts `/mnt`.
5. **storage bypass** — binds `/mnt/tmp` onto `/tmp` and overlays
   `/nix/store` onto the new disk (live ISO RAM + read-only squashfs workaround);
   idempotent, cleaned up at the end.
6. **system** — `nix build` the toplevel, `nixos-install --no-root-passwd`.
7. **dotfiles** — copied to `/mnt/home/<user>/.dotfiles` and seeded
   (`git init` + `origin` remote). No `.git` is bundled (295M), so updates on
   the new machine: `git pull` after the remote is reachable.
8. **home-manager** — activationPackage built on the ISO, `nix copy --to
   /mnt/nix`, activated inside the target as the user. Falls back to the old
   in-chroot `home-manager switch` method if that fails.
9. **rekey reminder** for agenix (secrets are sealed to the old host key —
   unavoidable without your age identity on the ISO).
10. cleanup + post-boot instructions.

## Notes & limitations

- **Wallpapers submodule** (129M, git LFS-ish) is not bundled. After first
  login with working SSH keys: `git submodule update --init --recursive`.
- **First login**: root has no password (`--no-root-passwd`) and the agenix
  passwords can't decrypt until the rekey, so log in via SSH using the
  pubkey in `system/<host>/configuration.nix`, or set a password from the
  installer: `nixos-enter --root /mnt -- passwd quil`.
- Network is required during install (inputs come from the locked flake,
  cache.nixos.org; pins are exactly what flake.lock says).
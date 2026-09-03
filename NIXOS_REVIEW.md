# NixOS Config Review — snowflake (ASUS G14)

Review date: 2026-09-03 · Flake: nixpkgs `9fbb54b33e` (2026-08-26) · No files were edited.

Overall this is a clean, well-organized "dendritic" flake-parts + import-tree layout. The
following are **suggestions only**, ordered by severity. Every item is verified against the
repo as of this date.

---

## 1 · High priority (correctness / latent breakage)

### 1.1 — home-manager input is 16 months older than nixpkgs
`flake.lock`: `home-manager` is pinned to **2025-04-24** (`abfad3d2`) while `nixpkgs` is
**2026-08-26**. `inputs.nixpkgs.follows` only shares the nixpkgs *revision* — it does **not**
update home-manager's own source. Home-manager modules from Apr 2025 are being evaluated
against a Aug 2026 nixpkgs. It works today, but you are one option-rename away from a broken
eval, and you're missing newer HM features (e.g. hyprland Lua config support, new module
options).
- Run `nix flake lock --update-input home-manager` and (ideally) do one full
  `nixos-rebuild switch` + `home-manager switch` right after.
- Your `users/quil/home.nix` already uses `wayland.windowManager.hyprland.configType = "lua"`
  and `lib.generators.mkLuaInline` — confirm the *pinned* HM actually has these (they landed
  in master around the 25.05/26.05 cycle). This is the strongest argument for updating HM.

### 1.2 — `systemd.sysusers.enable = false` is a global footgun
`system/snowflake/configuration.nix`: comment says it fixes an agenix + persistence race — but
both `persist` imports are currently **commented out** (`# persist` in the system module list
and in `users/quil/home.nix`). With persistence inactive, this global disable is unnecessary
and can silently break user/group creation on other hosts or future changes.
- Remove it once you confirm `users.users.quil` and `root` still get created at activation.
- If you re-enable impermanence later, prefer the upstream agenix/impermanence ordering fix
  instead of disabling sysusers system-wide.

### 1.3 — Screen locking is silently broken: `hyprlock` is never installed
`users/…/hyprland-modules/power-management.nix`:
`lock_cmd = "pidof hyprlock || hyprlock";` — but `hyprlock` appears nowhere in any package
list. The lock command fails at runtime (no-op) every time `hypridle` times out.
- Add `programs.hyprlock.enable = true;` (or `pkgs.hyprlock`) in the hyprland home module.

### 1.4 — Five duplicate/conflicting keybinds in `binds.nix`
Hyprland keeps the first matching bind and warns on duplicates, so the later ones are dead:
| combo | first binding | second binding (silently dead) |
|---|---|---|
| `SUPER + M` | spotify_player | `submap("moniter_select")` |
| `SUPER + SHIFT + P` | `window.pseudo()` | `grimblast screen` (all screens) |
| `SUPER + SHIFT + Up` | focus workspace r+1 | `window.swap(up)` |
| `SUPER + SHIFT + Down` | focus workspace r-1 | `window.swap(down)` |
- Rename/merge these (e.g. move second bindings to use ALT instead of SHIFT, window-move conflicts to
  `SUPER + CTRL + arrows` etc.).

### 1.5 — Dead keybinds / startup commands referencing uninstalled apps
Referenced but **not installed anywhere** in the config:
- `rog-control-center` (binds `SUPER + SHIFT + R`) — separate from `asusctl`
- `polychromatic-controller` (binds `SUPER + ALT + R`)
- `obs`, `gimp`, `lutris` (binds) — `lutris` is even commented out in `games.nix`
- `cliphist` — used by startup: `wl-paste --watch cliphist store`, not in any package list
- `xwaylandvideobridge` — used in startup + window_rule, not installed
- `windscribe`/etc. not applicable…
Either add the packages or drop the bindings. Minimum fix: add `cliphist` and
`xwaylandvideobridge`, since they're load-bearing for startup behavior.

### 1.6 — Hardcoded hibernate `resume_offset` will silently break
`system/universal/g14/g14.nix`:
`kernelParams = [ … "resume_offset=533760" ]`, `resumeDevice = "/dev/mapper/root_vg-root"`,
with the 40G swapfile on the btrfs `/swap` subvolume (`disko.nix`).
- `resume_offset` is the swapfile's first block extent — it changes whenever the swapfile is
  recreated (disko re-provisioning, subvolume wipe, etc.). A stale offset makes resume hang or
  boot fresh.
- Verify it with `filefrag -v /swap/swapfile` and document it, or make it robust (compute in
  an initrd service, or move swap to a dedicated LUKS/partition layout).

### 1.7 — Open WebUI points at the wrong llama.cpp port
- `system/…/services/llamacpp.nix`: `port = 8080`
- `system/…/services/openwebui.nix`: `OPENAI_API_BASE_URL = "http://localhost:8081/v1"`
- `system/…/services/hermes.nix`: base_url `http://localhost:8080/v1` (consistent with
  llamacpp)
All three modules are currently commented out, but when you enable them, Open WebUI will be
pointing at 8081 while llama.cpp serves 8080 → chat requests fail. Fix the port in
`openwebui.nix` (or add a `port`-sharing comment).

### 1.8 — Two divergent `permittedInsecurePackages` lists
- System (`configuration.nix`): `"electron-40.10.5"`
- Home (`users/quil/home.nix`): `"electron-39.8.10"` (and the system list references
  `electron-40.10.5`, i.e. two different stale versions of the same package).
- Since both module sets run on the same machine, centralize in one place (NixOS-side)
  and **bump to whatever electron your nixpkgs has now** — or better, find which package
  drags the old electron and fix the package, so you don't run known-insecure builds.

---

## 2 · Medium (duplication / modernization)

### 2.1 — Six flake inputs are never used (dead weight in `flake.lock`)
Each of these is declared in `flake.nix` inputs but never referenced by any module:
`nixos-hardware`, `firefox-addons`, `rust-overlay`, `llama-cpp-turboquant`,
`hyprland-plugins`, `split-monitor-workspaces`.
- No `.nix` file uses them (grep: only a comment in `hyprland.nix` mentions
  `hyprland-plugins`).
- Remove them from `flake.nix`; they otherwise get updated on every `nix flake update` for no
  benefit and can drag in unrelated breakage. You still get Rust via `rustup` in `rust.nix`,
  llama.cpp via `pkgs.llama-cpp-rocm`, etc.

### 2.2 — Hyprland config is split across two modules that fight each other
- NixOS side (`system/universal/GUI/hyprland/hyprland.nix`): `programs.hyprland` package +
  portalPackage, `xdg.portal` config, session env vars.
- Home side (`users/…/hyprland/hyprland.nix` + modules): `wayland.windowManager.hyprland`
  package + portalPackage, `xdg.portal` **again** (identical values), and the same env vars
  via `settings.env` (MOZ_ENABLE_WAYLAND, ELECTRON_OZONE_PLATFORM_HINT, AQ_DRM_DEVICES,
  WLR/AQ_NO_HARDWARE_CURSORS duplicated in `environment.sessionVariables`).
Pick one owner: keep the compositor config wholly in home-manager (recommended, since your
binds/monitors/startup live there) and strip the duplication from the NixOS module.
- Also worth evaluating: upstream is moving to UWSM (`programs.uwsm` /
  `services.hyprland`). Not urgent, but plan for it; your Lua-config style is already heading
  the right way. Verify your pinned HM supports `configType = "lua"` (see 1.1).

### 2.3 — Dormant impermanence layer
- `system/universal/system/persist.nix` (wipe-root initrd service, `/persist` filesystem) and
  `users/quil/persist.nix` are well-written but **not imported anywhere** (both `# persist`
  commented). The `/persist` subvolume still exists in `disko.nix`.
- Decide: fully enable impermanence (you've already written the machinery) or delete the
  dormant modules + `systemd.sysusers` hack (1.2). Half-wired state is where boot bugs live.
- If you keep the wipe-root script, note `date "+%Y-%m-%-d_%H:%M:%S"` mixes `%m` (padded) with
  `%-d` (unpadded) — cosmetic, but tidy it, and the `find … -mtime +30` loop also yields the
  parent `old_roots` dir itself.

### 2.4 — Power management stacks overlap
`g14.nix` runs `auto-cpufreq` **and** `asusd` profiles, and sets `amd_pstate=active`
- `auto-cpufreq` explicitly recommends disabling `amd_pstate`; with `amd_pstate=active` your
  governor is managed by the pstate driver, so auto-cpufreq's governor switching is a no-op.
- Meanwhile `power-management.nix` (home) shells out to `asusctl profile set …` on AC/battery
  changes, which is the "proper" AMD-APU path on a G14.
- Suggest picking one: keep `asusd` + the power-monitor script, drop `auto-cpufreq`
  (or vice versa) — you'll get more predictable behavior and fewer moving parts.

### 2.5 — Monitor assumptions are hardcoded
- `monitors.nix` declares both `eDP-1` and `eDP-2` (only one internal panel exists on a G14)
  and `AQ_DRM_DEVICES=/dev/dri/card1:/dev/dri/card2` (device *index* ordering can change
  across boots/kernel reconfigurations).
- `hyprland.nix` (home) also sets `GDK_SCALE = "2"` — on top of monitor scale 1.25, GTK apps
  get 2×2.5× scaling and will render enormous. Remove `GDK_SCALE` unless you've verified app
  sizes are correct.

### 2.6 — Cosmetic dead code in `configuration.nix`
- `systemd.services.nvidia-powerd.enable = lib.mkForce false` — no nvidia anywhere; delete.
- `systemd.user.services.blueman-applet.enable = lib.mkForce false` — you enable `services.blueman`
  in `bluetooth.nix`; forcing the applet off on a *nonexistent* user service is fragile.
  If you don't want the tray applet (quickshell has its own BT widget), remove the force line
  entirely rather than mkForce'ing undefined services.
- `autoUpgrade = { enable = false; … }` — fully disabled; remove the block.
- `nix.optimise.automatic = true` **and** `nix.settings.auto-optimise-store = true` do the same
  job; keep one.
- commented `# password = "1234"` — remove.
- `nixpkgs.config.allowUnfreePredicate = _: true` is redundant when `allowUnfree = true` is
  already set (both files) — remove the predicate in both places.
- `systems = [ "x86_64-linux" "aarch64-linux" ]` but every configuration hardcodes
  `x86_64-linux` — drop `aarch64-linux` until a host uses it.

### 2.7 — `stdenv` used without being passed
`users/quil/home.nix`:
`inputs.agenix.packages.${stdenv.hostPlatform.system}.default` — `stdenv` is not in the module
args (only `pkgs, username, inputs, config, …`). It only works if some imported module
silently injects it. Use `pkgs.stdenv.hostPlatform.system` (you already pass `system` on the
NixOS side and `system` in `extraSpecialArgs` — use those).

### 2.8 — Dead/empty modules
- `system/snowflake/secrets.nix` and `system/universal/system/secrets.nix` are both `{}`;
  agenix secrets live in `configuration.nix` directly. Remove the modules + imports.
- `system/universal/system/qt5.nix` is `{}` — dead; qtwayland is already added as a home
  package. Remove.
- `system/universal/applications/winboat.nix` references `pkgs.winboat` with no visible
  overlay/package wiring from the `winboat` input — it's commented out in the host config, so
  it's dead either way. Either wire `inputs.winboat` properly or delete input + module.
- `users/…/bars/waybar/` (waybar.nix + generate_waybar_stylix.py) is never imported
  (quickshell is the active bar) — delete or restore.

---

## 3 · Security & hardening (all currently fine — optional extras)

- `security.nix` is good: ssh key-only, `AllowUsers`, sudo `execWheelOnly` + timeout,
  dmesg/ptrace/kptr_restrict, mmap ASLR bits. Keep.
- OpenSSH is enabled with key-only auth but there's no fail2ban/attempt limiting. If this
  host is ever reachable beyond LAN/tailscale, add `services.fail2ban` or keep it firewalled
  (firewall currently allows nothing inbound — good).
- `creaml`/`creamlinux` module is present — comments say test-only; nothing to do, just note
  the repo ships it.
- `firewall.allowedTCPPorts` empty + Steam remote-play/dedicated-server/local-transfer ports
  opened by `games.nix` only when Steam is enabled — fine, but be aware those rules are
  enabled whenever you import `games`.

---

## 4 · Repo / tooling hygiene

### 4.1 — Flake has no `checks`, so DeterminateCI builds nothing
`.github/workflows/determinate-ci.yml` runs Determinate CI with no `flake.checks` / outputs to
build → the pipeline is effectively a no-op (or builds only the machine config, which requires
your host key for agenix and will fail in CI without secrets).
- Add `flake.checks` (e.g. `nixfmt-rfc-style` + `statix` + a `nixos-rebuild build --flake`
  dry eval like `nix flake check` won't need secrets if agenix secrets are git-tracked .age
  files — they are).
- Consider `determinate-nixd`/`magic-nix-cache` — not required, but a cheap win for CI speed.

### 4.2 — Add a formatter + devShell
No `formatter` output is defined (you already install `nixfmt` in neovim.nix).
- `formatter.x86_64-linux = pkgs.nixfmt-rfc-style;` (+ optionally `nixfmt` in-tree) so
  `nix fmt` works. There is no devShell either — a tiny shell with `nixos-rebuild`,
  `home-manager`, `statix`, `deadnix` makes iteration nicer.

### 4.3 — `install.sh` is a 18KB bespoke installer
It works, but it's a maintenance liability. Consider replacing with the standard
`disko --mode disko` recipe + `nixos-anywhere`, or at least run it through `shellcheck`
in CI. The checkpoint/bind-mount/agenix-rekey logic is exactly what nixos-anywhere already
solves.

### 4.4 — Small correctness nits
- `dwm.nix` hardcodes `/home/quil/Documents/GitRepos/nixos-config/wallpaper.png` — stale
  path (repo lives at `~/.dotfiles`, wallpaper at `./wallpaper.png`).
- `flatpak.nix` pins `//25.08` runtimes and `vkSumi` `v0.0.7` — both will go stale; consider
  unpinned runtime refs (or documented bump cadence) and note `update.onActivation = true`
  makes every rebuild slightly slower (auto-update alone may be enough).
- `ollama.nix` imports `openwebui` transitively — enabling one drags in the other; decouple if
  you ever want Ollama without the web UI.
- `ctx-size = 192640` in `llamacpp.nix` — sanity-check that against VRAM for the 35B-A3B
  draft model; the 8 GB 6800S will likely spill context heavily. (Comment already hints at
  smaller values.)
- `networkmanager.wifi.powersave = true` can add latency for realtime-ish work (ssh, VOIP);
  consider `false` on battery mode if you notice.
- `neovim.nix` builds avante.nvim from source with trailing `|| true` — failures are silent;
  check `~/.config/nvim` logs after a switch if avante misbehaves.

---

## 5 · Suggested change order (if you want a plan)

1. **Update `home-manager` input** and re-switch (1.1) — do this first, alone, and verify.
2. Install `hyprlock` + `cliphist` + `xwaylandvideobridge`, fix duplicate binds (1.3–1.5).
3. Remove dead inputs (2.1), dead modules (2.8), and the sysusers hack (1.2).
4. Fix port mismatch in openwebui (1.7) before you next enable the AI stack.
5. Pick one power-management stack (2.4) and fix hibernate offset documentation (1.6).
6. Dedupe hyprland/portal/env config (2.2), consolidate insecure-package lists (1.8).
7. Add flake checks + formatter (4.1–4.2) so CI starts earning its keep.

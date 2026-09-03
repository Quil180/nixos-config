# pi-dotfiles

A zero-dependency Pi extension that makes updating this NixOS flake safe and easy.
Plain ESM (`.mjs`), no imports, no build step — it survives pi/nixpkgs churn and
impermanence with nothing to install.

## What it gives you

| Tool / command | Purpose |
|---|---|
| `dotfiles_audit` | Read-only health check: pin staleness (resolves `root.inputs` correctly — the classic flake.lock trap), unused inputs, missing `formatter`/`checks`/`devShells`, git state, and hygiene checks (sysusers+persist mismatch, divergent `permittedInsecurePackages`, openwebui/llama.cpp port mismatch, missing hyprlock, duplicate hyprland keybinds). |
| `dotfiles_update` | Targeted `nix flake update` (chosen inputs, all *used* inputs, or `staleOnly`), pre-update git snapshot + plain backup, `nixos-rebuild build` + `home-manager build` verification (never activates), auto-rollback on failure, optional `apply: true` for the system/home switch. Supports `dryRun`. |
| `/dotfiles` | Human command: runs the audit and drops the report into the editor. |

## Activation

The extension is wired **project-locally** via `.pi/settings.json` in this repo,
so it loads whenever pi runs from inside the repo (the natural place to do
update work). Trust the project when pi asks.

To make it available **globally** (any directory), add one line to
`~/.pi/agent/settings.json` (declaratively: in
`users/universal/applications/productivity/pi.nix`, add to the `builtins.toJSON`
object):

```json
"extensions": ["/home/quil/.dotfiles/extensions/pi-dotfiles/index.mjs"]
```

then `home-manager switch` (or `updh`).

## Usage snippets

- "Audit the flake" → the model calls `dotfiles_audit`.
- "Update the stale inputs, but don't switch" →
  `dotfiles_update` with `{ staleOnly: true }` (defaults: snapshot + verify, no switch).
- "Update everything and rebuild" →
  `dotfiles_update` with `{ apply: true }` — run it at the console so the sudo
  password prompt works; if pi can't `sudo -n`, the tool tells you the exact
  command to run instead.
- `/dotfiles` in the TUI → report in your editor.

## Safety model

- Never activates the system unless you pass `apply: true`.
- `verify: true` (default) does eval/build checks of both the NixOS system and
  the home configuration before anything is applied.
- `snapshotGit` (default) commits `flake.lock` before and after the update; the
  plain `/tmp` backup + git reset restores the previous lock if verification
  fails (`revertOnFailure`, default).

## Development

Pure functions (audit, plan, update pipeline) are exported for testing:

```bash
# syntax
node --check extensions/pi-dotfiles/index.mjs
# functional smoke test against the real repo
node --input-type=module -e "
import { readFile } from 'node:fs/promises';
import * as ext from './extensions/pi-dotfiles/index.mjs';
const deps = {
  exec: async (c, a) => ({ stdout: '', stderr: '', code: 0 }),
  read: async (p) => readFile(p, 'utf8'),
  exists: async (p) => { try { await import('node:fs/promises').then(m => m.access(p)); return true; } catch { return false; } },
  env: { HOME: process.env.HOME },
};
const r = await ext.computeInputStatus(process.cwd(), deps);
console.log(ext.renderAuditReport(r));
"
```
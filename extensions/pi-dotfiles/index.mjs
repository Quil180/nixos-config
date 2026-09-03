/**
 * pi-dotfiles — NixOS/dotfiles update assistant
 *
 * Makes keeping this flake updated safe and easy:
 *   - `dotfiles_audit`  : read-only health check of flake.nix + flake.lock
 *                         (stale pins, unused inputs, hygiene checks).
 *   - `dotfiles_update` : targeted `nix flake update` with pre-update git
 *                         snapshot, eval/build verification, optional
 *                         system + home switch, and automatic rollback.
 *   - `/dotfiles`       : human command; runs the audit and drops the report
 *                         into the editor.
 *
 * Zero dependencies by design: plain ESM, no imports, no build step, so it
 * keeps working across pi/nixpkgs churn and under impermanence. All IO goes
 * through the injected `exec`/`read`/`exists` deps (pi.exec in production,
 * child_process in tests). The pure functions are exported so the logic can
 * be exercised with `node`.
 */

// ---------------------------------------------------------------------------
// Pure helpers (dependency-injected, node-testable)
// ---------------------------------------------------------------------------

/** Escape a string for use inside a RegExp. */
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * Walk up from `start` looking for a directory containing flake.nix + flake.lock.
 * Falls back to ~/.dotfiles. Returns absolute path or null.
 */
export async function findRepoDir(start, deps) {
  let dir = start;
  const home = deps.env?.HOME ?? "/home/quil";
  while (dir && dir !== "/") {
    if ((await deps.exists(`${dir}/flake.nix`)) && (await deps.exists(`${dir}/flake.lock`))) {
      return dir;
    }
    const next = dir.replace(/\/[^/]*$/, "") || "/";
    if (next === dir) break;
    dir = next;
  }
  if ((await deps.exists(`${home}/.dotfiles/flake.nix`)) &&
      (await deps.exists(`${home}/.dotfiles/flake.lock`))) {
    return `${home}/.dotfiles`;
  }
  return null;
}

/**
 * Strip the `inputs = { ... }` block from flake.nix text (brace-matched).
 * Returns text with that block removed, so usage scans don't count the
 * declaration itself as usage.
 */
export function stripInputsBlock(flakeNix) {
  const marker = flakeNix.search(/inputs\s*=\s*\{/);
  if (marker === -1) return flakeNix;
  let depth = 1;
  let i = marker + flakeNix.slice(marker).indexOf("{") + 1;
  while (i < flakeNix.length && depth > 0) {
    if (flakeNix[i] === "{") depth++;
    else if (flakeNix[i] === "}") depth--;
    i++;
  }
  return flakeNix.slice(0, marker) + flakeNix.slice(i);
}

/** Remove nix comments (`# ...`) from a line. */
const stripComment = (line) => {
  const idx = line.indexOf("#");
  return idx === -1 ? line : line.slice(0, idx);
};

/** Collect all *.nix file paths in the repo (respecting git, else find). */
export async function listNixFiles(repo, deps) {
  const git = await deps
    .exec("git", ["ls-files", "-z", "--", "*.nix"], { cwd: repo })
    .catch(() => ({ stdout: "" }));
  if (git.stdout.trim()) {
    return git.stdout.split("\0").filter(Boolean).map((f) => `${repo}/${f}`);
  }
  const out = await deps.exec(
    "find",
    [repo, "-type", "f", "-name", "*.nix", "-not", "-path", "*/node_modules/*", "-print"],
    { cwd: repo },
  );
  return out.stdout.split("\n").filter(Boolean);
}

/**
 * Usage scan: after removing the flake.nix inputs block, count occurrences of
 * the input name (as `inputs.<name>` or as a bare word) across every non-
 * comment line of all .nix files. Skips matches inside double-quoted strings
 * for the bare-word count.
 */
function countUsage(texts, name) {
  let inputsRefs = 0;
  let bareRefs = 0;
  let commentRefs = 0;
  const inputsRe = new RegExp(`inputs\\.${esc(name)}\\b`, "g");
  const bareRe = new RegExp(`\\b${esc(name)}\\b`, "g");
  const strRe = /"(?:[^"\\]|\\.)*"/g;
  for (const raw of texts) {
    for (const rawLine of raw.split("\n")) {
      const line = stripComment(rawLine);
      const commentLine = rawLine.slice(0, line.length);
      inputsRefs += (line.match(inputsRe) ?? []).length;
      commentRefs += (commentLine.match(inputsRe) ?? []).length;
      bareRefs += (line.replace(strRe, '""').match(bareRe) ?? []).length;
    }
  }
  return { inputsRefs, bareRefs, commentRefs };
}

/**
 * Parse which inputs in flake.nix follow nixpkgs (`inputs.nixpkgs.follows`),
 * by brace-matching each `name = { ... }` entry inside the inputs block.
 * Follows info is NOT present in flake.lock leaf nodes, so we need this.
 */
export function parseFlakeFollows(flakeNix) {
  const marker = flakeNix.search(/inputs\s*=\s*\{/);
  if (marker === -1) return {};
  let depth = 1;
  let i = marker + flakeNix.slice(marker).indexOf("{") + 1;
  const start = i;
  while (i < flakeNix.length && depth > 0) {
    if (flakeNix[i] === "{") depth++;
    else if (flakeNix[i] === "}") depth--;
    i++;
  }
  const block = flakeNix.slice(start, i - 1);
  const follows = {};
  const entryRe = /(?:^|\n)\s*([A-Za-z0-9_-]+)\s*=\s*\{/g;
  let m;
  while ((m = entryRe.exec(block))) {
    const name = m[1];
    let d = 1;
    let j = m.index + m[0].length - 1;
    while (j < block.length && d > 0) {
      if (block[j] === "{") d++;
      else if (block[j] === "}") d--;
      j++;
    }
    const inner = block.slice(m.index + m[0].length - 1, j);
    follows[name] = /inputs\.nixpkgs\.follows\s*=\s*["']nixpkgs["']/.test(inner);
  }
  return follows;
}

/** Parse flake.lock JSON into declared inputs with metadata. */
export function parseLock(lockText, follows = {}) {
  const lock = JSON.parse(lockText);
  const root = lock.nodes.root;
  const declared = Object.keys(root.inputs ?? {});
  const nixpkgsKey = root.inputs?.nixpkgs;
  const nixpkgsLast = lock.nodes[nixpkgsKey]?.locked?.lastModified ?? 0;
  const DAY = 86_400; // lastModified is epoch SECONDS
  const inputs = declared
    .map((name) => {
      const key = root.inputs[name];
      const node = lock.nodes[key] ?? {};
      const lastModified = node.locked?.lastModified ?? 0;
      return {
        name,
        key,
        rev: node.locked?.rev?.slice(0, 10) ?? "?",
        ref: node.locked?.ref ?? "",
        lastModified,
        date: lastModified ? new Date(lastModified * 1000).toISOString().slice(0, 10) : "?",
        gapDays: nixpkgsLast && lastModified ? Math.round((nixpkgsLast - lastModified) / DAY) : 0,
        followsNixpkgs: !!follows[name],
      };
    })
    .sort((a, b) => b.gapDays - a.gapDays);
  return { lock, nixpkgsLast, inputs };
}

/** Git state of the repo. */
export async function gitState(repo, deps) {
  const raw = await deps
    .exec("git", ["status", "--porcelain"], { cwd: repo })
    .catch(() => ({ stdout: "" }));
  const lines = raw.stdout.split("\n").filter(Boolean);
  const lockChanged = lines.some((l) => /(^| )flake\.lock( |$)/.test(l));
  return { dirty: lines.length > 0, lockChanged, lines: lines.slice(0, 15) };
}

/**
 * Full audit. Returns a structured status object; `renderAuditReport` turns it
 * into markdown. Cheap: no nix commands, only file reads + git.
 */
export async function computeInputStatus(repo, deps) {
  const [flakeNix, lockText] = await Promise.all([
    deps.read(`${repo}/flake.nix`),
    deps.read(`${repo}/flake.lock`),
  ]);
  const follows = parseFlakeFollows(flakeNix);
  const { inputs, nixpkgsLast } = parseLock(lockText, follows);
  const flakeNixWithoutInputs = stripInputsBlock(flakeNix);

  const files = await listNixFiles(repo, deps);
  const texts = await Promise.all(files.map((f) => deps.read(f)));
  // Flake.nix body counts as usage; the inputs block itself does not.
  const bodyTexts = [flakeNixWithoutInputs, ...texts.filter((_, i) => !files[i].endsWith("/flake.nix"))];

  const usage = new Map();
  for (const inp of inputs) {
    usage.set(inp.name, countUsage(bodyTexts, inp.name));
  }

  const usedInputs = inputs.filter((i) => usage.get(i.name).inputsRefs > 0 || usage.get(i.name).bareRefs > 0);
  const commentOnly = inputs.filter((i) => usage.get(i.name).inputsRefs === 0 && usage.get(i.name).bareRefs === 0 && usage.get(i.name).commentRefs > 0);
  const unused = inputs.filter((i) => usage.get(i.name).inputsRefs === 0 && usage.get(i.name).bareRefs === 0 && usage.get(i.name).commentRefs === 0);

  // Stale: follows nixpkgs but >14 days behind. Pinned refs (e.g.
  // nix-flatpak v0.6.0) never advance — flag but note the pin.
  const stale = inputs.filter(
    (i) => i.followsNixpkgs && i.gapDays > 14 && i.name !== "nixpkgs",
  );
  const stalePinned = stale.filter((i) => i.ref);
  const veryOld = inputs.filter((i) => !i.followsNixpkgs && i.lastModified && nixpkgsLast - i.lastModified > 180 * 86_400);
  const critical =
    stale.find((i) => i.name === "home-manager") ??
    stale.find((i) => !i.ref) ??
    null;

  const git = await gitState(repo, deps);
  const hygiene = await runHygieneChecks(repo, files, deps);

  return {
    repo,
    git,
    nixpkgsLast,
    inputs,
    usedInputs,
    unused,
    commentOnly,
    stale,
    stalePinned,
    veryOld,
    critical,
    hygiene,
  };
}

/** Hygiene checks distilled from a code review of this repo (2026-09). */
export async function runHygieneChecks(repo, files, deps) {
  const findFile = async (rel) =>
    files.find((f) => f === `${repo}/${rel}`) ?? (await deps.exists(`${repo}/${rel}`) ? `${repo}/${rel}` : null);
  const read = async (rel) => {
    const f = await findFile(rel);
    return f ? deps.read(f) : null;
  };
  const results = [];

  const [configNix, homeNix, powerMgmt, llamacpp, openwebui, binds] = await Promise.all([
    read("system/snowflake/configuration.nix"),
    read("users/quil/home.nix"),
    read("users/universal/desktop-environments/hyprland/hyprland-modules/power-management.nix"),
    read("system/universal/services/llamacpp.nix"),
    read("system/universal/services/openwebui.nix"),
    read("users/universal/desktop-environments/hyprland/hyprland-modules/binds.nix"),
  ]);

  if (configNix && /systemd\.sysusers\.enable\s*=\s*false/.test(configNix)) {
    const persistImported = /^\s*persist\s*$/m.test(configNix);
    results.push({
      severity: persistImported ? "info" : "warn",
      id: "sysusers-persist",
      text: persistImported
        ? "`systemd.sysusers.enable = false` (agenix/persist race workaround) is still set — persist is active, keep it."
        : "`systemd.sysusers.enable = false` is set but the persist modules are commented out — the workaround is unnecessary and can silently break user/group creation.",
    });
  }

  if (configNix && homeNix) {
    const sys = new Set([...configNix.matchAll(/"electron-[\d.]+"/g)].map((m) => m[0]));
    const home = new Set([...homeNix.matchAll(/"electron-[\d.]+"/g)].map((m) => m[0]));
    const onlySys = [...sys].filter((e) => !home.has(e));
    const onlyHome = [...home].filter((e) => !sys.has(e));
    if (onlySys.length || onlyHome.length) {
      results.push({
        severity: "warn",
        id: "insecure-divergence",
        text: `permittedInsecurePackages differs between system and home (system: ${onlySys.join(", ") || "—"}, home: ${onlyHome.join(", ") || "—"}). Centralize + bump.`,
      });
    }
  }

  if (llamacpp && openwebui) {
    const port = llamacpp.match(/^\s*port\s*=\s*(\d+)\s*;/m)?.[1];
    const urlPort = openwebui.match(/OPENAI_API_BASE_URL\s*=\s*"http:\/\/localhost:(\d+)\/v1"/)?.[1];
    if (port && urlPort && port !== urlPort) {
      results.push({
        severity: "warn",
        id: "openwebui-port",
        text: `llama.cpp serves on :${port} but openwebui.nix points OPENAI_API_BASE_URL at :${urlPort}.`,
      });
    }
  }

  if (powerMgmt && /hyprlock/.test(powerMgmt)) {
    // Scan all files EXCEPT power-management.nix (the only place that mentions
    // hyprlock as a command) for an actual hyprlock package/program install.
    const others = files.filter((f) => !f.endsWith("power-management.nix"));
    const texts = await Promise.all(others.map((f) => deps.read(f))).catch(() => []);
    if (!/programs\.hyprlock|pkgs\.hyprlock/.test(texts.join("\n"))) {
      results.push({
        severity: "warn",
        id: "hyprlock-missing",
        text: "hypridle calls `hyprlock` but hyprlock is not installed anywhere — screen lock is a silent no-op.",
      });
    }
  }

  if (binds) {
    const seen = new Map();
    const re = /hl\.bind\(\s*(?:mod \.\. )?"([^"]+)"\s*,/g;
    let m;
    while ((m = re.exec(binds))) {
      const combo = m[1];
      seen.set(combo, (seen.get(combo) ?? 0) + 1);
    }
    const dupes = [...seen.entries()].filter(([, n]) => n > 1);
    if (dupes.length) {
      results.push({
        severity: "warn",
        id: "duplicate-binds",
        text: `Duplicate keybinds (later ones are dead): ${dupes.map(([combo]) => `\`${combo}\``).join(", ")}.`,
      });
    }
  }

  if (homeNix && /stdenv\./.test(homeNix) && !/^\s*stdenv,?\s*$/m.test(homeNix.slice(0, homeNix.indexOf(":")))) {
    results.push({
      severity: "info",
      id: "stdenv-arg",
      text: "`stdenv` is used in users/quil/home.nix but is not declared among the module args — prefer `pkgs.stdenv.hostPlatform.system`.",
    });
  }

  const flakeSource = await read("flake.nix");
  if (flakeSource) {
    const missing = [];
    if (!/^\s*formatter\b/m.test(stripInputsBlock(flakeSource))) missing.push("formatter");
    if (!/^\s*checks\b/m.test(stripInputsBlock(flakeSource))) missing.push("checks");
    if (!/^\s*devShells\b/m.test(stripInputsBlock(flakeSource))) missing.push("devShells");
    if (missing.length) {
      results.push({
        severity: "info",
        id: "flake-outputs",
        text: `flake.nix defines no ${missing.join("/")} output — CI (DeterminateCI) has nothing to build and \`nix fmt\` has no formatter.`,
      });
    }
  }

  return results;
}

const fmtDays = (d) => (d > 0 ? `${d}d` : d === 0 ? "same" : `${-d}d newer`);

/** Markdown report from the audit status. */
export function renderAuditReport(s) {
  const L = [];
  L.push(`# Flake audit — ${s.repo.replace(/^.*\//, "")}`);
  L.push("");
  L.push(s.git.dirty
    ? `Git: **dirty** (${s.git.lines.length} change${s.git.lines.length === 1 ? "" : "s"}${s.git.lockChanged ? ", flake.lock modified" : ""})`
    : "Git: clean");
  L.push("");
  L.push(`## Inputs (${s.inputs.length} declared)`);
  L.push("");
  L.push("| input | pin date | vs nixpkgs | follows? | status |");
  L.push("|---|---|---|---|---|");
  for (const i of s.inputs) {
    const status = s.critical?.name === i.name
      ? "🔴 **critically stale**"
      : s.stale.includes(i)
        ? (i.ref ? `🟡 stale (pinned @${i.ref})` : "🟡 stale")
        : s.veryOld.includes(i)
          ? "🟡 old"
          : "🟢 ok";
    L.push(`| ${i.name} | ${i.date} | ${i.gapDays ? fmtDays(i.gapDays) : "—"} | ${i.followsNixpkgs ? "follows" : "—"} | ${status} |`);
  }
  L.push("");
  if (s.stale.length) {
    const unpinned = s.stale.filter((i) => !i.ref);
    const pinned = s.stale.filter((i) => i.ref);
    if (unpinned.length) L.push(`Update candidates (follow nixpkgs, >14d behind): **${unpinned.map((i) => i.name).join(", ")}**`);
    if (pinned.length) L.push(`Stale but pinned by ref (move the ref to update): ${pinned.map((i) => `${i.name}@${i.ref}`).join(", ")}`);
  }
  L.push("");
  if (s.unused.length) {
    L.push(`Declared but never referenced (drop from flake.nix inputs): **${s.unused.map((i) => i.name).join(", ")}**`);
  }
  if (s.commentOnly.length) {
    L.push(`Referenced only in comments (still dead): ${s.commentOnly.map((i) => i.name).join(", ")}`);
  }
  L.push("");
  L.push("## Hygiene");
  L.push("");
  if (!s.hygiene.length) {
    L.push("No issues found.");
  }
  for (const h of s.hygiene) {
    L.push(`- [${h.severity}] ${h.text}`);
  }
  L.push("");
  L.push("## Suggested flow");
  L.push("");
  L.push("1. `dotfiles_update` with `inputs: [\"home-manager\"]` **first, alone**, followed by a rebuild — the riskiest pin.");
  L.push("2. `dotfiles_update` with `staleOnly: true` for the remaining stale candidates, `verify: true`.");
  L.push("3. Drop unused inputs from flake.nix, then `nix flake update` prunes them for free.");
  L.push("4. Only after the verify build passes: `dotfiles_update` with `apply: true` to switch.");
  L.push("");
  return L.join("\n");
}

/** Compute the update plan for the dotfiles_update tool. */
export async function planUpdate(repo, deps, params) {
  const status = await computeInputStatus(repo, deps);
  const requested = (params.inputs ?? []).map((x) => String(x).trim()).filter(Boolean);
  const declaredNames = new Set(status.inputs.map((i) => i.name));
  const unknown = requested.filter((n) => !declaredNames.has(n));

  let targets;
  if (params.staleOnly) {
    targets = status.stale.map((i) => i.name);
  } else if (requested.length) {
    targets = requested.filter((n) => declaredNames.has(n));
  } else {
    targets = status.usedInputs.map((i) => i.name);
  }
  // home-manager first when present; it is the riskiest pin.
  targets = [...targets].sort((a, b) =>
    (a === "home-manager" ? -1 : 0) - (b === "home-manager" ? -1 : 0),
  );

  // Default host/user names come from flake.nix itself (configurations.*).
  const flakeSource = await deps.read(`${repo}/flake.nix`);
  const hostDetected = flakeSource.match(/configurations\.nixos\.([\w-]+)\.module/)?.[1];
  const userDetected = flakeSource.match(/configurations\.home\.([\w-]+)\.module/)?.[1];
  const target = params.target ?? hostDetected ?? "snowflake";
  const user = params.user ?? userDetected ?? "quil";
  return {
    status,
    targets,
    unknown,
    target,
    user,
    willUpdateLock: targets.length > 0,
  };
}

/**
 * The update pipeline. Returns a report object (also rendered to markdown by
 * the caller). Never touches the running system unless `apply` is true.
 */
export async function runUpdate(repo, deps, params, onStep) {
  const plan = await planUpdate(repo, deps, params);
  const { status, targets, unknown, target, user } = plan;
  const steps = [];
  const step = async (msg, fn) => {
    onStep?.(msg);
    try {
      const r = await fn();
      steps.push({ msg, ok: true, ...r });
      return r;
    } catch (e) {
      steps.push({ msg, ok: false, error: String(e?.message ?? e) });
      throw e;
    }
  };

  if (params.dryRun) {
    return {
      plan,
      dryRun: true,
      steps,
      summary: `Dry run: would update ${targets.length ? targets.join(", ") : "nothing"}${targets.length ? ` then verify${params.apply ? " and switch" : ""}` : ""}.`,
    };
  }

  for (const n of unknown) {
    steps.push({ msg: `skipping unknown input: ${n}`, ok: true, skipped: true });
  }
  if (!targets.length) {
    return { plan, steps, summary: "Nothing to update — all used inputs are fresh." };
  }

  // 1. Pre-update lock snapshot (plain file backup, then optional git commit).
  const backupPath = `/tmp/flake.lock.bak-${Date.now()}`;
  await step("backing up flake.lock", async () => {
    await deps.write(backupPath, await deps.read(`${repo}/flake.lock`));
    return { backupPath };
  });

  let snapshotCommit = null;
  if (params.snapshotGit) {
    await step("git snapshot of flake.lock", async () => {
      const gitLockChanged = (await gitState(repo, deps)).lockChanged;
      if (!gitLockChanged) return { commit: null };
      await deps.exec("git", ["add", "flake.lock"], { cwd: repo });
      await deps.exec("git", ["commit", "--only", "flake.lock", "-m", "chore(flake): snapshot lock before update"], { cwd: repo });
      snapshotCommit = (await deps.exec("git", ["rev-parse", "--short", "HEAD"], { cwd: repo })).stdout.trim();
      return { commit: snapshotCommit };
    });
  }

  // 2. Targeted lock update.
  const before = JSON.parse(await deps.read(`${repo}/flake.lock`));
  let updated = [];
  try {
    await step(`nix flake update (${targets.join(", ") || "all"})`, async () => {
      const args = ["flake", "update", "--flake", repo, ...targets];
      const res = await deps.exec("nix", args, { cwd: repo, timeout: params.timeouts?.lock ?? 600_000 });
      const after = JSON.parse(await deps.read(`${repo}/flake.lock`));
      for (const name of targets) {
        const rootRef = before.nodes.root.inputs[name];
        const b = before.nodes[rootRef]?.locked?.rev ?? "?";
        const a = after.nodes[rootRef]?.locked?.rev ?? "?";
        if (b !== a) updated.push({ name, from: b.slice(0, 10), to: a.slice(0, 10) });
      }
      return { updated, output: res.stdout.slice(-2000) };
    });
  } catch (e) {
    // The lock update itself failed — restore the backup and unwind the
    // snapshot commit so the repo is exactly as it was.
    if (params.revertOnFailure !== false) {
      await deps.write(`${repo}/flake.lock`, await deps.read(backupPath)).catch(() => {});
      if (snapshotCommit) {
        await deps.exec("git", ["reset", "--hard", "HEAD^"], { cwd: repo }).catch(() => {});
      }
    }
    return {
      plan,
      steps,
      updated: [],
      verifyOk: false,
      lockFailed: true,
      summary: `nix flake update failed (${String(e?.message ?? e).split("\n")[0]}). Lock restored from backup.`,
    };
  }

  // 3. Verification builds (eval-only — safe, no activation).
  let verifyOk = true;
  try {
    if (params.verify !== false) {
      await step(`nixos-rebuild build .#${target}`, async () => {
        const res = await deps.exec(
          "nixos-rebuild", ["build", "--flake", `.#${target}`],
          { cwd: repo, timeout: params.timeouts?.verify ?? 1_800_000 },
        );
        return { output: res.stdout.slice(-1500) };
      });
      await step(`home-manager build .#${user}`, async () => {
        const res = await deps.exec(
          "home-manager", ["build", "--flake", `.#${user}`],
          { cwd: repo, timeout: params.timeouts?.verify ?? 1_200_000 },
        );
        return { output: res.stdout.slice(-1500) };
      });
    }
  } catch (e) {
    verifyOk = false;
  }

  if (!verifyOk) {
    if (params.revertOnFailure !== false) {
      await deps.write(`${repo}/flake.lock`, await deps.read(backupPath)).catch(() => {});
      if (snapshotCommit) {
        await deps.exec("git", ["reset", "--hard", "HEAD^"], { cwd: repo }).catch(() => {});
      } else {
        await deps.exec("git", ["checkout", "--", "flake.lock"], { cwd: repo }).catch(() => {});
      }
    }
    return {
      plan,
      steps,
      verifyOk: false,
      summary: `Verification **failed** after updating ${updated.map((u) => u.name).join(", ") || "inputs"}. flake.lock restored from backup${snapshotCommit ? " and the snapshot commit was reset" : ""}. Fix the breakage before applying.`,
      updated,
    };
  }

  // 4. Optional switch (needs sudo for the system; home-manager runs as user).
  // Failures here do NOT throw: the report records them and stops, so the
  // agent gets actionable output (e.g. "run sudo nixos-rebuild switch")
  // instead of a bare tool error.
  let systemApplied = false;
  let homeApplied = false;
  const applyError = [];
  if (params.apply) {
    const sysRes = await deps.exec(
        "sudo", ["-n", "nixos-rebuild", "switch", "--flake", `.#${target}`],
        { cwd: repo, timeout: params.timeouts?.switch ?? 1_800_000 },
      ).catch((e) => ({ code: -1, stdout: "", stderr: String(e?.message ?? e) }));
    if (sysRes.code === 0) {
      systemApplied = true;
      steps.push({ msg: "sudo nixos-rebuild switch", ok: true });
    } else {
      const err = sysRes.stderr.slice(-500) || sysRes.stdout.slice(-500);
      const needsManual = /password|sudo/i.test(err);
      steps.push({
        msg: "sudo nixos-rebuild switch", ok: false, error: err,
        needsManual,
      });
      applyError.push(needsManual
        ? "sudo switch needs a password at the console — run `sudo nixos-rebuild switch --flake .#" + target + "` yourself."
        : `system switch failed: ${err}`);
    }

    if (systemApplied) {
      const hmRes = await deps.exec(
          "home-manager", ["switch", "--flake", `.#${user}`, "-b", "backup"],
          { cwd: repo, timeout: params.timeouts?.switch ?? 900_000 },
        ).catch((e) => ({ code: -1, stdout: "", stderr: String(e?.message ?? e) }));
      if (hmRes.code === 0) {
        homeApplied = true;
        steps.push({ msg: "home-manager switch", ok: true });
      } else {
        steps.push({ msg: "home-manager switch", ok: false, error: hmRes.stderr.slice(-500) || hmRes.stdout.slice(-500) });
        applyError.push("home-manager switch failed — check the step below.");
      }
    }
  }

  // 5. Final commit of the updated lock.
  if (params.snapshotGit && updated.length) {
    await deps.exec("git", ["add", "flake.lock"], { cwd: repo }).catch(() => {});
    await deps.exec(
      "git", ["commit", "--only", "flake.lock", "-m", `chore(flake): update ${updated.map((u) => u.name).join(", ")}`],
      { cwd: repo },
    ).catch(() => {});
  }

  const gens = await deps
    .exec("nixos-rebuild", ["list-generations", "--flake", `.#${target}`], { cwd: repo })
    .catch(() => ({ stdout: "" }));

  return {
    plan,
    steps,
    updated,
    verifyOk: true,
    systemApplied,
    homeApplied,
    applyError,
    summary:
      `Updated ${updated.length ? updated.map((u) => `${u.name} ${u.from}→${u.to}`).join(", ") : "nothing (already current)"}. ` +
      `Verified build ✓. ` +
      (params.apply
        ? (systemApplied ? "System switched ✓. " : "System NOT switched. ") +
          (homeApplied ? "Home switched ✓." : "") +
          (applyError.length ? ` ${applyError.join(" ")}` : "")
        : "(apply not requested)"),
    rollback: "nixos-rebuild --rollback",
    generations: gens.stdout.split("\n").slice(-4).join("\n"),
  };
}

// ---------------------------------------------------------------------------
// Pi wiring
// ---------------------------------------------------------------------------

/**
 * Convert this environment's deps into the {exec, read, exists, write, env}
 * shape used by the pure helpers. pi.exec(cmd, args, {cwd, timeout, signal}).
 */
const makeDeps = (pi, ctx) => ({
  exec: (cmd, args, opts = {}) => pi.exec(cmd, args, { ...opts, signal: ctx?.signal }),
  read: async (p) => (await pi.exec("cat", [p])).stdout,
  exists: async (p) => (await pi.exec("test", ["-e", p], {})).code === 0,
  write: async (p, txt) => {
    const b64 = Buffer.from(txt).toString("base64");
    await pi.exec("mkdir", ["-p", p.replace(/\/[^/]*$/, "")]);
    return pi.exec("sh", ["-c", `printf %s '${b64}' | base64 -d > '${p}'`], { cwd: "/" });
  },
  env: { HOME: process.env.HOME ?? "/home/quil" },
});

export default function register(api) {
  // Tools run with the session's cwd; resolve the repo once per call.
  const repoOf = async (ctx) => {
    const repo = await findRepoDir(ctx?.cwd ?? process.cwd(), makeDeps(api, ctx));
    if (!repo) throw new Error("No flake.nix/flake.lock found — run pi from inside the dotfiles repo (or ~/.dotfiles).");
    return repo;
  };

  api.registerTool({
    name: "dotfiles_audit",
    label: "Audit Dotfiles Flake",
    description:
      "Read-only health check of the NixOS dotfiles flake: pin staleness (e.g. home-manager vs nixpkgs), unused inputs declared in flake.nix, missing formatter/checks/devShells outputs, git state, and known hygiene issues (sysusers+persist mismatch, divergent permittedInsecurePackages, openwebui/llama.cpp port mismatch, missing hyprlock, duplicate hyprland keybinds).",
    promptSnippet: "Audit flake.nix/flake.lock health (stale pins, unused inputs, hygiene)",
    promptGuidelines: [
      "Use dotfiles_audit before any flake update to surface stale pins (especially home-manager vs nixpkgs) and unused inputs.",
      "Use dotfiles_update (dryRun/verify defaults) to update inputs safely; only set apply=true to switch the system.",
    ],
    parameters: {
      type: "object",
      properties: {
        focus: {
          type: "string",
          enum: ["all", "inputs", "hygiene"],
          description: "What to report. Default: all.",
        },
      },
    },
    async execute(_id, params, signal, onUpdate, ctx) {
      const repo = await repoOf(ctx);
      const deps = makeDeps(api, ctx);
      onUpdate?.({ content: [{ type: "text", text: `Auditing ${repo}…` }], details: {} });
      const status = await computeInputStatus(repo, deps);
      const report = renderAuditReport(status);
      return {
        content: [{ type: "text", text: report }],
        details: {
          repo,
          dirty: status.git.dirty,
          stale: status.stale.map((i) => i.name),
          unused: status.unused.map((i) => i.name),
          commentOnly: status.commentOnly.map((i) => i.name),
          hygiene: status.hygiene.map((h) => ({ id: h.id, severity: h.severity })),
        },
      };
    },
  });

  api.registerTool({
    name: "dotfiles_update",
    label: "Update Dotfiles Flake",
    description:
      "Safely update the dotfiles flake lock: targeted `nix flake update` on chosen inputs (or all used inputs / stale-only), optional git snapshot of flake.lock, verification via `nixos-rebuild build` + `home-manager build` (never activates), automatic rollback to the previous lock on failure, and optionally `apply: true` to run `sudo nixos-rebuild switch` + `home-manager switch`. Always starts with a plan; dryRun shows it without touching anything.",
    promptSnippet: "Update flake inputs with snapshot, verify, and optional switch",
    promptGuidelines: [
      "Use dotfiles_update for flake updates instead of raw `nix flake update` so the lock gets snapshotted and verified first.",
      "Run dotfiles_update with apply=false by default; only set apply=true when the user explicitly wants the system switched.",
    ],
    parameters: {
      type: "object",
      properties: {
        inputs: {
          type: "array",
          items: { type: "string" },
          description: "Input names to update. Omit to update all *used* inputs (dead inputs excluded).",
        },
        staleOnly: {
          type: "boolean",
          description: "Only update inputs that follow nixpkgs and are >14 days behind (default false).",
        },
        dryRun: {
          type: "boolean",
          description: "Show the plan without changing anything (default false).",
        },
        verify: {
          type: "boolean",
          description: "Build-verify before switching (default true).",
        },
        apply: {
          type: "boolean",
          description: "After verified build, run sudo nixos-rebuild switch + home-manager switch (default false; requires sudo password at the console).",
        },
        snapshotGit: {
          type: "boolean",
          description: "Commit the pre-update flake.lock in git and commit the update after success (default true).",
        },
        revertOnFailure: {
          type: "boolean",
          description: "Restore the previous flake.lock when verification fails (default true).",
        },
        target: {
          type: "string",
          description: "NixOS configuration name, e.g. snowflake.",
        },
        user: {
          type: "string",
          description: "Home configuration name, e.g. quil.",
        },
      },
    },
    async execute(_id, params, signal, onUpdate, ctx) {
      const repo = await repoOf(ctx);
      const deps = makeDeps(api, ctx);
      const cfg = {
        inputs: params.inputs,
        staleOnly: !!params.staleOnly,
        dryRun: !!params.dryRun,
        verify: params.verify !== false,
        apply: !!params.apply,
        snapshotGit: params.snapshotGit !== false,
        revertOnFailure: params.revertOnFailure !== false,
        target: params.target,
        user: params.user,
      };
      const step = (msg) => onUpdate?.({ content: [{ type: "text", text: msg }], details: { step: msg } });

      const plan = await planUpdate(repo, deps, cfg);
      step(`Plan: update ${plan.targets.length ? plan.targets.join(", ") : "nothing"}${cfg.apply ? " + switch" : ""}${cfg.dryRun ? " (dry run)" : ""}`);
      if (plan.unknown.length) step(`note: unknown inputs ignored — ${plan.unknown.join(", ")}`);

      const result = await runUpdate(repo, deps, cfg, step);
      const report = [
        `# dotfiles_update — ${result.dryRun ? "dry run" : "result"}`,
        "",
        result.summary,
        "",
        ...result.steps.map((s) => (s.ok ? `- ✓ ${s.msg}` : s.skipped ? `- → ${s.msg}` : `- ✗ ${s.msg}: ${s.error ?? ""}`)),
        ...(result.generations ? ["", "Latest generations:", "```", result.generations, "```"] : []),
        result.rollback ? ["", `Rollback: \`${result.rollback}\``] : [],
      ].flat();
      return {
        content: [{ type: "text", text: report.join("\n") }],
        details: {
          repo,
          targets: plan.targets,
          dryRun: !!cfg.dryRun,
          updated: (result.updated ?? []).map((u) => `${u.name}:${u.from}→${u.to}`),
          verifyOk: !!result.verifyOk,
          applied: !!result.systemApplied || !!result.homeApplied,
          ok: (result.steps ?? []).every((s) => s.ok || s.skipped),
        },
      };
    },
  });

  // Human command: /dotfiles — audit now, dump the report into the editor.
  api.registerCommand("dotfiles", {
    description: "Audit the dotfiles flake and put the report in the editor (usage: /dotfiles audit)",
    handler: async (args, ctx) => {
      const repo = args.trim() ? args.trim() : await findRepoDir(ctx.cwd, makeDeps(api, ctx)).catch(async () => (await findRepoDir("/", makeDeps(api, ctx))) ?? null);
      const resolved = typeof repo === "string" && (await makeDeps(api, ctx).exists(`${repo}/flake.nix`)) ? repo : await repoOf(ctx);
      const deps = makeDeps(api, ctx);
      const status = await computeInputStatus(resolved, deps);
      const report = renderAuditReport(status);
      if (ctx.hasUI) ctx.ui.setEditorText(report);
      ctx.ui.notify(`Inspected ${resolved} — report is in the editor.`);
    },
  });
}
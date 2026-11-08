# Changelog

Releases are tagged `vX.Y.Z`. Before `1.0.0` the plugin can still change in ways that need an edit to your config. The notes say when.

## 0.6.0 (2026-11-08)

The plugin now passes the directory's policy for organizations that are not Verified. That policy allows no pre-approved tools beyond Read, Grep, Glob and LS, and no scripts or fixtures in the plugin folder. Two things change for marketplace users. Nothing in your `bdd-config.md` needs to change.

### What you will notice

- **Permission prompts.** The seven commands no longer pre-approve `Bash`, `Write` or `Edit`. Claude Code asks before each shell command and file write, unless your own settings allow them. To keep the old behavior, allow those tools in your project settings.
- **The decision log script.** The marketplace plugin no longer ships `decisions.sh`. With `decision_log` set to `on` and no script, `design` and `triage` go on without records and say "Nothing was recorded". `reconcile` stops and says it needs the project install. `init --detect` no longer offers to turn the log on.

### Project-file installs

- No change. `install.sh` copies `decisions.sh` and the schema from the repo root, and writes each command's former `allowed-tools` line back into the installed copy. Re-run it to update. Nothing in your project behaves differently.

### Repo

- `scripts/`, `schemas/` and `evals/` moved to the repo root. They are not part of the plugin.
- Run the evals with `bash evals/run.sh`, which builds a temporary copy of the plugin with the cases inside it. The nightly workflow does the same.
- A test fails if the plugin folder holds a file type the directory refuses, a file that starts with `#!`, package-manager config, or an `allowed-tools` entry beyond Read, Grep, Glob and LS.
- The known gaps list a new entry: no eval runs the decision log script. The earlier entry on broad grants is gone, with its pack marked superseded.

## 0.5.0 (2026-11-08)

The plugin now lives in a `plugin/` folder, so the directory scan and the cache hold only what users install. Nothing in your project or your `bdd-config.md` needs to change.

### Commands

- `/bdd:implement` has a red-first check. After the step code is written, it sees each scenario fail for the stated reason before it counts as passing. It uses a natural red when there is one, and otherwise breaks the step code on purpose and restores it. A scenario it could not see red keeps the unautomated tag, and the report says so on a `Red-first:` line.

### Repo

- The plugin moved into `plugin/`: `commands/`, `agents/`, `scripts/`, `schemas/`, `bdd-config.template.md`, `evals/`, a short `README.md` and a `LICENSE`. The marketplace entry points at `./plugin`.
- To run the plugin from a clone, use `claude --plugin-dir <clone>/plugin`. Pointing it at the clone root no longer works. Use `claude plugin validate plugin` and `claude plugin eval plugin` too.
- `install.sh` reads from `plugin/`. It says "could not clone" when the clone fails, and "no plugin/ folder" when a source has none. In both cases it leaves your project untouched.
- A plugin listing icon, and a "Tool permissions" section in the plugin README that says why the commands pre-approve `Bash`, `Write` and `Edit`.
- `docs/known-gaps.md` lists what the plugin does not check, with why and what would close each gap.
- The CI token setup for the nightly evals moved from `plugin/evals/README.md` to `docs/evals-ci.md`.
- CI runs `claude plugin validate plugin --strict` on a pinned Claude Code version.

## 0.4.0 (2026-11-05)

The first pinned version. Until now the plugin had no version, so every merge to `main` reached users at once. From here, `plugin update` delivers a change when a new version is released. A project that installed the plugin earlier moves to `0.4.0` on its next update.

### Commands

- `/bdd:discover`, `/bdd:design`, `/bdd:implement`, `/bdd:run`, `/bdd:triage`, `/bdd:reconcile` and `/bdd:init`, framework-agnostic and driven by `bdd-config.md`.
- `/bdd:design` lints the draft before showing it, through a temporary `.bdd-draft-*` file, and acts only on findings in the draft. It lists assumptions for vague acceptance criteria and shows scenarios in full.
- `/bdd:implement` works for projects without a UI and groups steps by risk (`step_batch`), so the loop needs fewer test runs.
- `/bdd:run` never reports zero tests run as a pass, and can pick a verifier by name or file.
- `/bdd:init --detect` proposes skill roles, hints for `generate` and the decision log, and audits values that already exist. Its audit ends with one fixed line. It also reports files left over from the older project-file install.

### Config

- Rows: `prepare`, `step_batch`, `decision_log`, `discovery_dir`, `lint`, `glossary_file`, `scenario_id_prefix` and `automated_tag`. Every row is optional.
- `steps_dir` can list several paths, comma-separated, for projects whose step code is split across folders.
- Your existing `bdd-config.md` is never overwritten. The installer prints a note for each newer row your config lacks.

### Decision log

- Optional. `decisions.sh` records approved decisions, and `/bdd:triage` and `/bdd:reconcile` read it.

### Repo

- Evals with `claude plugin eval` for five commands, and a workflow that runs four of them on demand and nightly once the repository variable `EVALS_NIGHTLY` is set.
- Apache-2.0 licence.

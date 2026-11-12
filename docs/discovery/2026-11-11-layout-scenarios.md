# Discovery: the layout checks as scenarios

Input: `tests/test_layout.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder, one question at a time. The behavior already exists. Values are marked "from code".

## Story

The repo keeps the plugin in its own `plugin/` folder, so users get only what the directory scans. Migrate the checks of `tests/test_layout.sh` to scenarios. A migration adds no checks.

## Agreed examples (all from code)

Where the manifests live
- **E1** The plugin manifest is at `plugin/.claude-plugin/plugin.json`.
- **E2** The marketplace file stays at `.claude-plugin/marketplace.json` in the repo root.
- **E3** The repo root holds no plugin manifest.
- **E4** The marketplace entry's source is `./plugin`.

What is inside `plugin/` and what stays out
- **E5** `plugin/` has `commands` and `agents`. Neither is at the repo root.
- **E6** `bdd-config.template.md` is in `plugin/`, not at the repo root.
- **E7** The repo root keeps `tests`, `docs`, `.github`, `install.sh`, `CLAUDE.md`, `CHANGELOG.md`, `README.md`, `LICENSE`, `evals`, `scripts`, `schemas`.
- **E8** `plugin/` holds none of `tests`, `docs`, `.github`, `install.sh`, `CLAUDE.md`, `CHANGELOG.md`, `evals`, `scripts`, `schemas`.

The listing README and icon
- **E9** `plugin/README.md` has at least 40 words outside code and links `https://github.com/godrose/bdd-skills`.
- **E10** It has a "## Tool permissions" section, mentions `known-gaps.md`, says "pre-approve nothing", and does not say "pre-approve `Bash`".
- **E11** The icon is a PNG, square, 512 to 2048 px per side, under 2 MB.

The plugin licence copy
- **E12** `plugin/LICENSE` is identical to the root `LICENSE`.

CI and eval wiring
- **E13** `.gitignore` ignores `evals/results/`.
- **E14** `CLAUDE.md` and the README show how to run and validate the plugin.
- **E15** The evals workflow and the evals README name `evals/run.sh`.
- **E16** The CI workflow validates the plugin and pins the claude-code version.
- **E17** `plugin/` never names the CI token setup. `docs/evals-ci.md` exists and is pointed to from the evals README and the docs index.

The installer reads from `plugin/`
- **E18** `install.sh` sets `PLUGIN_DIR="$SOURCE_DIR/plugin"` and says "no plugin/ folder" when it is missing.

The directory's file-type and tool policy
- **E19** Tracked files in `plugin/` are only allowed types (plus `LICENSE` and `.gitignore`).
- **E20** No tracked file in `plugin/` starts with `#!`.
- **E21** No tracked file in `plugin/` is a package-manager file.
- **E22** Each command and agent file's tool line lists only Read, Grep, Glob and LS.
- **E23** The docs index points to `directory-policy.md`. `CLAUDE.md` says "refuses".
- **E24** The docs index says the older packs follow the earlier layout.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Is the "lib.sh sets PLUGIN" check migrated? | No. | It tests the bash helper, not the repo, and the library is deleted at the end of the series. |
| 2 | Where do the permissions note (E10) and the docs-index lines (E23, E24) go? | Permissions note under the listing README. Docs-index lines in their own groups. | The builder's groups had no home for them. Approved with the checklist. |

## Existing users

Nothing changes in a user's project or in the plugin folder. The version does not change.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new feature file runs beside the bash files until the bash file is deleted.

## Exclusions

- The `lib.sh sets PLUGIN` check. Reason: see decision 1.
- Any new layout check. Reason: a migration adds none.

## Kept as they are

- E19 to E21 read tracked files only. An untracked file in `plugin/` is not seen.
- E22 reads only values in double quotes. A tool list without quotes is not checked.

# Discovery: move the plugin into a `plugin/` folder

Input: the directory's validation report for this repo (run on 2026-11-08 against the private repository), the directory's pre-submission checklist, and a probe of `claude plugin eval` on a throwaway layout.

## Story

A maintainer submits the plugin to the directory. The scan reads the plugin folder. Today that is the whole repo, so the scan reads tests, CI workflows, docs and eval fixtures as if they were plugin code. Four findings held the version for a reviewer. Three of them come from files that are not part of the plugin.

The plugin should live in its own folder, so the scan reads only what users install.

## What the validation report showed

Nothing blocked, and the name and publisher checks passed. The findings, with the files behind them:

| Finding | Result | Source | Plugin file? |
|---------|--------|--------|--------------|
| Pre-approves broad shell access in `allowed-tools`, 7 findings | Policy hold | the seven commands | yes |
| Image or font file the code could run | Policy hold | `tests/test_readme.sh` names `docs/demo/story.gif` | no |
| Uses a credential from the user's machine, 2 findings | Policy hold | `.github/workflows/evals.yml`, `tests/test_evals.sh` | no |
| Files the validator could not inspect | Policy hold | `docs/demo/story.gif` | no |
| No icon | Warning | | |
| `CLAUDE.md` at the plugin root is not loaded | Warning | `CLAUDE.md` | no |
| Download-and-run command, 9 findings | Warning | README and `install.sh` text | no |
| Later-only rules for Verified organizations | Note | `design.md` `allowed-tools`, `evals/*/fixture` scripts | partly |

## Existing behavior (from the repo and a probe)

- The plugin and the repo share one root. `.claude-plugin/plugin.json` and `marketplace.json` sit together. The marketplace entry has `"source": "./"`.
- The plugin tree is `commands/`, `agents/`, `scripts/`, `schemas/` and `bdd-config.template.md`. The commands call `${CLAUDE_PLUGIN_ROOT}/scripts/decisions.sh` and `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.
- `install.sh` copies from those folders into a user's project. It finds its source next to itself.
- `claude plugin eval` reads cases from `evals/` **below the plugin**. A probe with `experimental.evals` set to `../evals` printed: it "must stay inside the plugin root (no ..)". So the cases must move with the plugin.
- The tests read the plugin tree through `$ROOT/commands`, `$ROOT/agents` and similar paths, about 100 places.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Folder name | `plugin/`. | Says what it is. The builder chose it. |
| 2 | What goes inside | `.claude-plugin/plugin.json`, `commands/`, `agents/`, `scripts/`, `schemas/`, `bdd-config.template.md`, `evals/`, a short `README.md` and a `LICENSE`. | The plugin tree, plus `evals/` because the eval tool needs it there. |
| 3 | What stays at the root | `.claude-plugin/marketplace.json`, `tests/`, `docs/`, `.github/`, `install.sh`, `CLAUDE.md`, `CHANGELOG.md`, `README.md`, `LICENSE`, `.gitignore`, `.gitattributes`. | None of it is installed by plugin users. `install.sh` is the project-file installer. |
| 4 | Marketplace entry | `"source": "./plugin"`. The manifest `version` stays in `plugin/.claude-plugin/plugin.json`. | The marketplace file stays where the portal and users expect it. |
| 5 | Plugin README | A short listing README of about 150 words: what the plugin does, the install commands, and a link to the full README. | The directory shows it as the listing text and needs at least 40 words. The builder chose a short one. |
| 6 | `LICENSE` in the folder | A copy of the root `LICENSE`. A test fails if the two differ. | Users get only the plugin folder. Apache 2.0 asks that recipients get a copy. A symlink is not accepted. |
| 7 | Moving files | `git mv`, in one commit, so history and blame follow the files. | |
| 8 | Behavior of the commands | No change. | This is a layout change. |
| 9 | The `allowed-tools` hold | Not touched here. It needs its own discovery. | It changes how often users see permission prompts. |
| 10 | Version | No bump in this change. The next release PR bumps and lists the layout change in the changelog. | Feature PRs never bump. |
| 11 | How tests find the plugin | One variable, `PLUGIN="$ROOT/plugin"`, set in `tests/lib.sh`. The tests use it for the plugin tree. | One place to change. |
| 12 | Older packs | Left as written. `docs/README.md` says paths in older packs follow the earlier layout. | Packs are records of their day. |
| 13 | Keep the layout from regressing | CI runs `claude plugin validate plugin` and fails on any finding. The version of Claude Code is pinned in the workflow. | Validation needs no login. A moved file or a broken manifest is caught on the pull request, not at submission. |

## Existing users

- **Installed from the marketplace at `0.4.0`:** nothing changes until a new version is released. The cache is keyed by version. A trial after this pack checks what a marketplace update does to an install at the same version.
- **A fresh install from `main`:** reads `./plugin` from the new marketplace file. The commands are the same.
- **`claude --plugin-dir <clone>`:** stops working, because the clone root no longer holds a manifest. The README and `CLAUDE.md` say to use `<clone>/plugin`.
- **A marketplace added from a local clone:** works. The source path is relative to the marketplace file.
- **Project-file installs (`install.sh`):** the same command and result. The installer reads its source from `plugin/`.
- **The tag `v0.4.0`:** keeps the old layout. It is not changed.
- **A user's own files:** nothing is written into their projects by this change.

## First run

A fresh install behaves as today. A contributor who clones the repo sees `plugin/` and a short note in the README on running the plugin from it.

## Edge and negative cases

1. A contributor runs `claude plugin validate .` at the root: it validates the marketplace and reports that the root holds no plugin. The README names `claude plugin validate plugin`.
2. `claude plugin eval` is run at the root: it finds no eval cases. The README and the workflow say `claude plugin eval plugin`.
3. `evals/results/` moves with the folder. The ignore rule must still cover it.
4. A path in the commands that is relative to the repo root: none today. The commands use `${CLAUDE_PLUGIN_ROOT}`.
5. `tests/check_release.sh` and the version tests read `plugin/.claude-plugin/plugin.json`. They must fail clearly if the file is missing.
6. The evals workflow uploads results from `evals/results/`. It must use the new path.
7. `install.sh` run from a copy with no `plugin/` folder: stop with a clear message.

## Candidate exclusions

Exclusions 1 to 5 follow from the decisions. Exclusions 6 and 7 were confirmed by the builder.

1. No change to a command's text or behavior.
2. No change to the plugin name `bdd` or the marketplace name.
3. No second plugin and no `plugins/` folder.
4. No narrowing of `allowed-tools`. Decision 9.
5. No move of `tests/`, `docs/` or `.github/` into the plugin folder.
6. The eval fixtures keep their scripts for now. They produce only the "Verified organizations later" notes.
7. No other new CI job. The validate step in decision 13 is the only addition.

## Tests to write first

Each must fail before the change.

- `plugin/.claude-plugin/plugin.json` exists and holds the version. The root has no `.claude-plugin/plugin.json`.
- The marketplace entry's source is `./plugin`.
- The plugin folder holds `commands/`, `agents/`, `scripts/`, `schemas/`, `bdd-config.template.md` and `evals/`.
- The root holds none of `commands/`, `agents/`, `scripts/`, `schemas/` or `bdd-config.template.md`.
- `plugin/README.md` has at least 40 words outside code blocks and links the root README.
- `plugin/LICENSE` is identical to the root `LICENSE`.
- The existing tests read the plugin tree through `PLUGIN`, and pass.
- The README and `CLAUDE.md` say `--plugin-dir <clone>/plugin`.
- The evals workflow and the README run `claude plugin eval plugin`.
- `ci.yml` runs `claude plugin validate plugin` with a pinned Claude Code version.

## Trial after the change

On a clean profile, install `bdd@gennadyverdel-plugins` at `0.4.0`. Point the marketplace at the branch and run an update. Record what Claude Code does. Then install fresh from the branch and confirm the seven commands and the agent load.

## Readiness

Ready for `bdd:design`. No open questions. Decisions 2 to 13, the edge cases and every exclusion are confirmed.

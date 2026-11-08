# docs

This repo uses its own method. A larger change starts with a discovery pack, and the pack is kept here. Read them to see how a decision was made and what it replaced.

Every pack is a record of its day. A pack that a later one reversed carries a "Superseded" note at the top. The current behavior is in the commands, the README and the tests, not here.

Paths in the older packs follow the earlier layout, where `commands/`, `agents/`, `scripts/` and `evals/` sat at the repo root. They now live in `plugin/`.

## discovery/

One pack per change: questions, examples, edge cases, exclusions and decisions with reasons. A test fails if a pack is missing from this list.

| Pack | Change |
|------|--------|
| `2026-11-01-detect-skill-roles.md` | Skill roles in `/bdd:init --detect` |
| `2026-11-02-design-assumptions.md` | `design` lists the assumptions behind vague acceptance criteria |
| `2026-11-02-implement-framework-neutral.md` | `implement` for projects without a UI |
| `2026-11-02-prepare-row.md` | The `prepare` row, for things the tests need built first |
| `2026-11-02-step-batch.md` | Group steps by risk so the implement loop needs fewer runs |
| `2026-11-02-then-assertion-check.md` | Check what a reused Then step asserts |
| `2026-11-02-track-commits.md` | Stop bumping the plugin version on every change (superseded) |
| `2026-11-02-verifier-selection-and-tag-defaults.md` | Verifier selection by name or file, and tag defaults |
| `2026-11-02-zero-tests-ran.md` | A run that executes zero tests is not a pass |
| `2026-11-04-dogfood-bdd-netcore.md` | The plugin run on a real brownfield project, and what it found |
| `2026-11-04-init-audit-and-leftovers.md` | `init --detect` audits existing values and finds old installs |
| `2026-11-05-eval-spike.md` | A spike with `claude plugin eval` |
| `2026-11-05-first-pinned-release.md` | The first pinned release, `0.4.0` |
| `2026-11-05-lint-in-design-and-layered-steps.md` | Lint on the draft, several step folders, `generate` for IDE frameworks |
| `2026-11-05-pending-generate-and-decision-log.md` | `@pending` scenarios, `generate`, and the decision log from `init --detect` |
| `2026-11-05-rename-repo-bdd-skills.md` | Rename the repo to `bdd-skills` (marketplace name superseded in part) |
| `2026-11-08-red-first-and-known-gaps.md` | The red-first check in `implement`, and a known-gaps file |
| `2026-11-08-plugin-in-subfolder.md` | Move the plugin into a `plugin/` folder, so the directory scan reads only plugin files |
| `2026-11-08-evals-ci-out-of-plugin.md` | Move the CI token setup out of the plugin folder, after the second validation report |
| `2026-11-08-allowed-tools-decision.md` | Keep the broad `allowed-tools` grants (superseded) |
| `2026-11-08-directory-policy.md` | Meet the directory's file and tool policy: no grants, no scripts or fixtures in the plugin |

Maintainer notes for the nightly evals are in `evals-ci.md`.

## known-gaps.md

What the plugin does not check, or checks only in part. Each gap says why it is still open and what would close it. A test checks the shape of every entry.

## superpowers/

Working papers from the first design of the plugin, written before it was packaged. They explain why the method looks as it does.

- `specs/` hold the design decisions. They are useful background.
- `plans/` are step-by-step build plans written for a coding agent. They are historic.
- `dry-runs/` are paper walk-throughs of two commands.

These papers use the old project-form names (`bdd-design`, `.claude/scripts/decisions.sh`). The plugin names are `bdd:design` and so on. The behavior described may have changed since.

## demo/

The recording shown at the top of the README.

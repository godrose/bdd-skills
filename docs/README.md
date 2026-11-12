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
| `2026-11-09-deliver.md` | `/bdd:deliver`: one conversation from a description to verified scenarios, for a PM with a developer watching |
| `2026-11-10-design-title-check.md` | `bdd:design` checks that a scenario asserts what its title claims (Pass D) |
| `2026-11-10-discover-look-first.md` | `bdd:discover` looks at what exists before the first question and handles shown values (Step 0) |
| `2026-11-10-discover-flow-runs.md` | A scripted flow run for `bdd:discover`: a real headless session, a model playing the product manager, rules counted on the transcript |
| `2026-11-11-deliver-no-developer.md` | `bdd:deliver` reports parked technical stops as plain risks, for a person with no developer |
| `2026-11-11-deliver-flow-runs.md` | A scripted flow run for `bdd:deliver`, and a way to compare two runs to see a regression |
| `2026-11-11-scenario-suite.md` | The repo's own test suite as scenarios that run, migrated one file at a time |
| `2026-11-11-layout-scenarios.md` | The checks on the plugin folder layout, migrated to scenarios |
| `2026-11-11-decisions-scenarios.md` | The checks on the decision log script, migrated to scenarios |
| `2026-11-11-readme-scenarios.md` | The checks on the README's structure and promises, migrated to scenarios |
| `2026-11-11-skills-text-scenarios.md` | The checks on the command, agent and template text, migrated to scenarios in three pull requests (PR 1: structure, template, discover, run and verifier) |
| `2026-11-12-skills-text-scenarios-2.md` | The checks on the design and implement command text, migrated to scenarios (PR 2 of 3) |
| `2026-11-12-skills-text-scenarios-3.md` | The checks on the triage, reconcile, README and init text, migrated to scenarios (PR 3 of 3), with a tally of the whole old file |
| `2026-11-11-deliver-flow-scenarios.md` | The checks on the deliver flow harness, migrated to scenarios |
| `2026-11-11-discover-flow-scenarios.md` | The checks on the discover flow harness, migrated to scenarios |
| `2026-11-11-evals-scenarios.md` | The checks on the eval cases, their runner and the nightly workflow, migrated to scenarios |
| `2026-11-11-red-first-scenarios.md` | The checks on the red-first text in `implement` and on the known-gaps file, migrated to scenarios |
| `2026-11-11-deliver-text-scenarios.md` | The checks on the text of the deliver command, its trial record and its listings, migrated to scenarios |
| `2026-11-11-plugin-text-scenarios.md` | The checks on the plugin manifests, files and text rules, and the init, design and discover text, migrated to scenarios |
| `2026-11-12-approach-review.md` | Which text checks stay after the migration, and the rule for keeping them |
| `2026-11-12-required-setup-check.md` | `bdd:design` checks the setup a scenario depends on and reports a missing prerequisite as a setup error (issue 41) |
| `2026-11-12-deliver-gate2-plain-words.md` | `bdd:deliver` shows the second gate in plain words, and the audit table goes under a developer line |
| `2026-11-12-mutation-survivors.md` | Triage of the mutation survivors of the migrations, and the fix for the decisions script |
| `2026-11-12-deliver-checklist-existing-scenarios.md` | `bdd:deliver` keeps an existing scenario nobody asked about out of the checklist, and counts it on the Regression line |
| `2026-11-12-flows-perl-to-typescript.md` | The flow scripts move from Perl to TypeScript with the same rules, and the flow breaks are rewritten |
| `2026-11-12-mutation-apply-typescript.md` | The mutation runner applies a break with TypeScript, so Perl is no longer needed (option B, scope A) |

## trials/

Records of real working sessions with the plugin, kept as examples.

| Record | What it shows |
|--------|---------------|
| `2026-11-09-deliver-pm-session.md` | Two changes delivered with `/bdd:deliver` by a product manager and an assistant: the questions, the pushback and what it changed |
| `2026-11-11-deliver-on-its-own-suite.md` | `/bdd:init` and `/bdd:deliver` run on this repo to migrate one test file: the stops, the equivalence gap the mutation check found, and what it points to |

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

The recording shown at the top of the README, and a second one of a `/bdd:deliver` session (`deliver.gif`). It is a cut of a real run on a small demo app, in six steps from the description to the plain-words report.

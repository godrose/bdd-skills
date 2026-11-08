# Changelog

Releases are tagged `vX.Y.Z`. Before `1.0.0` the plugin can still change in ways that need an edit to your config. The notes say when.

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

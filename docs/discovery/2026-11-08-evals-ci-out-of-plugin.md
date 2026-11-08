# Discovery: keep the CI token setup out of the plugin folder

Input: the directory's second validation report, run on 2026-11-08 against `main` after the plugin moved into `plugin/`. Light pack: a documentation move, no behavior change.

## Story

The scan still held the version for a reviewer on a credential finding. It read two files in `plugin/evals/` and joined them: a note on `claude setup-token` for the nightly CI secret, and a grader regex in `design-lint-draft/case.yaml` (`draft[^\n]{0,80}...`) that it took for a command built at run time. Read together, it reported a credential leaving the machine in two steps.

Neither half is real. The plugin never reads a credential. The note tells a maintainer how to set a GitHub secret. The regex matches the agent's answer text.

## Findings in this report

| Finding | Source | Result |
|---------|--------|--------|
| Credential read plus data sent (hold) | `evals/README.md` (token note), `evals/design-lint-draft/case.yaml` (regex) | False positive. Fixed here. |
| Download-and-execute pattern (warning) | `evals/README.md` | The scan says documentation-only needs no change. Not changed. |
| Broad `allowed-tools`, unscoped `Write` and `Edit` | the seven commands | Own discovery. Not touched here. |
| Name `bdd` is a GitHub account | name check | Names are immutable. A reviewer decides. |

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Where the CI setup lives | `docs/evals-ci.md` at the repo root. It holds the former "In CI" section, unchanged. | It is for maintainers. Plugin users never install it. |
| 2 | What stays in `plugin/evals/README.md` | How to run cases by hand, the spike notes, and a short "In CI" pointer to the new file. | The eval tool needs `evals/` inside the plugin. The README can stay. |
| 3 | The grader regex | Not changed. | A grader change needs the evals re-run, and a check must not be loosened to quiet a scanner. Removing the credential half is enough to break the pair. |
| 4 | The download-and-execute warning | Left as is. | A warning that the scan itself says needs no change for documentation. |
| 5 | Keep it from returning | A test fails if anything under `plugin/` names `setup-token` or `CLAUDE_CODE_OAUTH_TOKEN`. The CI-section tests now read `docs/evals-ci.md`. | The scan reads the whole plugin folder. |
| 6 | Version | No bump. The next release PR lists it. | Feature PRs never bump. |

## Existing users

Nothing changes. Installed plugins do not use `evals/README.md`. The workflow file is not moved.

## First run

A fresh install is the same. A maintainer who looks for the CI setup in `plugin/evals/README.md` finds a pointer to `docs/evals-ci.md`.

## Exclusions

- No change to `evals.yml`, the grants, or any case.
- No change to a command's text.
- No move of `evals/` out of the plugin. The eval tool needs it there.
- No claim that the hold clears. A trial is the next Validate run.

## Tests first

Each fails before the change.

- Nothing under `plugin/` names `setup-token` or `CLAUDE_CODE_OAUTH_TOKEN`, except the ignored `results/` folder.
- `docs/evals-ci.md` exists, holds the CI setup, and is named in the docs index.
- `plugin/evals/README.md` points to `docs/evals-ci.md`.

## Trial after the change

Re-run Validate in the portal against the branch merged to `main`. Record whether the credential hold is gone.

## Readiness

Ready. No open questions.

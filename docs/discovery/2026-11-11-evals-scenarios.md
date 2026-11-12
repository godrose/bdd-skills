# Discovery: the eval checks as scenarios

Input: `tests/test_evals.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

The evals under `evals/` (six cases, the runner `evals/run.sh`, the nightly workflow `.github/workflows/evals.yml`) are run by hand or nightly with `claude plugin eval`. The repo checks their structure. Migrate the checks of `tests/test_evals.sh` to scenarios. A migration adds no checks.

## Text checks and behavior

Text checks of files: the six case files and their fixtures, `evals/README.md`, `docs/evals-ci.md`, `evals.yml`, `install.sh`, and two pins on the source of `evals/run.sh`.

Behavior: one. `evals/run.sh` is run with a stand-in for the eval tool first on the path. The stand-in lists what it would read.

## Overlap with existing scenarios

`layout-wiring.feature` already checks that `.gitignore` lists `evals/results/` and that `evals.yml` contains `evals/run.sh`. They are not written again.

## Agreed examples (all from code)

Case files (`evals-case-files.feature`, text)
- **E1** Each of the six cases has `case.yaml`, `scaffold.sh` and a fixture folder. Each `case.yaml` has `schema_version: "1.0"`, `scaffold_script: scaffold.sh`, `graders:` and `type: llm`, and at least 2 graders.
- **E2** Fixtures hold what each case needs. init-audit has a config and no `src/step-defs`. run-zero-tests has `fake-test.sh` saying "No test matches". design-lint-draft has the lint script, `reports.feature` and a config naming `fake-lint.sh`. The script checks `@TKT-` and the feature does not have it.

Graders (`evals-graders.feature`, text)
- **E3** design-vague-ac names its three plugin-only graders, `names-two-statuses` and `treats-finished-as-open`, and does not name `flags-finished-as-ambiguous`.
- **E4** design-lint-draft names its six graders and its three judge graders, does not use the old compound name, and has exactly 1 judge grader.
- **E5** init-audit, run-zero-tests and triage-approval-gate name their regex graders. The old compound names are absent.
- **E6** No judge grader in any of the six cases has a compound `-and-` name. The judge counts are 1, 2, 2, 3 and 1 for design-vague-ac, init-audit, run-zero-tests, triage-approval-gate and design-lint-draft.

Docs (`evals-docs.feature`, text)
- **E7** `install.sh` does not mention evals. (`.gitignore` is covered already.)
- **E8** `evals/README.md` has the cost-aware terms, the lint case grant, the run-zero-tests grants, the deliver-first-gate row and "two questions in one message".
- **E9** `docs/evals-ci.md` says "five of the six cases", `setup-token`, `## In CI`, `EVALS_NIGHTLY` and "only when the job fails".

Nightly workflow (`evals-workflow.feature`, text)
- **E10** It does not run `claude plugin eval plugin` directly. Its loop holds the five cases and leaves out design-lint-draft, which it still mentions.
- **E11** Triggers and rules: dispatch, a schedule gated by a variable, trust and cost flags, a read-only token, a time limit and an artifact. It has no PR trigger, no push trigger and no API key. The OAuth token is set on the step, not above it. It has no plain Bash grant and keeps the narrow `fake-test.sh` grant.
- **E12** It sets up the sandbox backend on the Linux runner.
- **E13** It is quiet when green: a short summary, the artifact only on failure, and exactly one `always()` step.
- **E13b** The workflow file has no em-dash.

The run script (`evals-run-script.feature`)
- **E14 (text)** `run.sh` has `claude plugin eval` and `mktemp -d`.
- **E15 (behavior)** After a run with the stand-in, every one of the six case folders is under the evals folder of the temporary copy.
- **E16 (behavior)** No case file is copied into that folder directly, and the plugin itself is copied (`commands` is there).

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How are the scenarios grouped? | Five files, by what a maintainer would notice: the case files, the graders, the docs, the workflow, the run script. | Smaller files, as asked. |
| 2 | Outline or separate scenarios for the six cases? | Scenario Outlines over the case names. | Only the name differs, and the old file looped over the same list. The builder chose to keep them. |
| 3 | How is the em-dash check written? | A scenario that the workflow file has no em-dash, using the step `it has no em-dash`. | The old check looked at lines added since `main`, in a bash file that is being replaced. The whole file is slightly stricter, and it has none today. Same choice as the README migration. |
| 4 | Are the two overlapping checks written again? | No. | `layout-wiring.feature` has them. A step is not written twice. |
| 5 | How is the behavior checked? | `run.sh` runs for real with a stand-in for the eval tool, first on the path. | The old file did the same. A real eval run is excluded. |
| 6 | The judge counts cover which cases? | Five. Not deliver-first-gate. | The old file counted only those five. |
| 7 | Is `tests/test_evals.sh` deleted in this change? | No. | The builder runs a mutation check against it first, then deletes it. |

## Existing users

Nothing changes in a user's project or in the plugin folder. `install.sh`, `evals/`, the workflow and `docs/evals-ci.md` are not edited. The new scenarios only read them.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new files run beside the bash file until it is deleted. The run script scenarios start `evals/run.sh` with a stand-in, so no model is called and nothing is written into `evals/results/`.

## Exclusions

- Any new eval check. Reason: a migration adds none.
- A real `claude plugin eval` run, the arguments the runner passes through, and the copy-back of results. Reason: a migration adds no checks, and the real run tests a model, not the repo.
- Deleting `tests/test_evals.sh` in this change. Reason: the builder runs a mutation check first.
- The bash helpers, and the check of `.gitignore` and of `evals/run.sh` in the workflow, which already exist as scenarios.

## Kept as they are

- E2 to E6 match plain text. A reordered or reformatted line passes as long as the text is there.
- E13 counts lines that contain `if: always()`.
- E11 flags the token only when a line indented by 8 spaces or less sets it.
- E9 and E8 check that fragments exist, not where.

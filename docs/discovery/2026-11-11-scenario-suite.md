# Discovery: the test suite as scenarios

Input: the suite as it is (15 bash files, about 2,700 lines, run by `bash tests/run.sh`), the helper-style refactor of `tests/test_flow_deliver.sh` (#50), and a discovery dialogue with the builder, one question at a time. The builder acts as product manager, developer and solo developer: the plugin is the product and the method is applied to itself.

## Story

The repo teaches a method where a plain sentence is both the specification and the check. Its own tests are bash. A reader has to read the setup of a case to learn what it guarantees, and nothing keeps a description in step with the code. The builder wants the suite to be living documentation: scenarios that run.

## Existing behavior

- `bash tests/run.sh` runs every `tests/test_*.sh`. CI runs it on Ubuntu with Node 22, after two `claude plugin validate` steps. Release PRs also run `tests/check_release.sh`.
- Four kinds of test: text pins on the plugin's Markdown (about 140), behavior of the scripts (the decision log, install, release), layout and policy checks, and the two flow harnesses with fakes.
- The shared library is about 60 lines: `pass`, `fail` and four `assert_` helpers.
- The only `.feature` files in the repo are fixtures under `evals/` and `flows/`. Fixture `c` already uses `@cucumber/cucumber` 11.3.0.
- The plugin folder may hold no package-manager config and no scripts. The repo root may.
- CI runs on every pull request, with no branch filter.

## Agreed examples

- **E1** `bash tests/run.sh` runs the scenarios and the bash files that remain, and fails if either fails.
- **E2** With no installed runner, `tests/run.sh` says to run `npm ci` and stops. A run in which no scenario ran is never a pass.
- **E3** A migrated file's checks are written as plain behavior sentences in `tests/features/`, with the steps in `tests/steps/` as TypeScript, and its bash file is deleted in the same pull request.
- **E4** Each migration pull request records a mutation check: the code is broken in several ways, and the old file and the new scenarios fail the same way.
- **E5** A scenario about a plugin text names a behavior the command promises, not the wording. Its step does the text check.
- **E6** CI installs the runner with `npm ci` and runs the same `bash tests/run.sh`. The two validate steps do not change.
- **E7** A local script runs what CI runs, in order: validate the plugin strictly, validate the marketplace, install the runner, run the tests. It says which step failed. It is run before every push.
- **E8** Every pull request in the series targets `base/scenario-suite`, and CI runs on it. Merging the base branch into `main` is a final, separate pull request, the builder's call.
- **E9** The plugin folder never gets a Node file, and the directory-policy test keeps passing.
- **E10** The pilot carries the root `package.json`, the lockfile, the CI change and the scenarios for the test run, the local CI script and the CI job. `tests/test_rename.sh` is deleted without being migrated: the rename is long done, and the file said to drop it once the old name was no longer a risk. (Changed from the first checklist after the builder's review of the pilot.)
- **E11** The release flow, `tests/check_release.sh` and the version rules do not change.
- **E12** The last pull request in the series removes `tests/lib.sh` and the bash runner loop.
- **E13** The steps are TypeScript. CI and the local script type-check them with `tsc --noEmit --noUnusedLocals --noUnusedParameters` after the runner is installed and before the tests run. A type error or an unused local fails the run at that step.
- **E14** In the last pull request of the series, once no bash file is left, `tests/features/` and `tests/steps/` move to a top-level `specs/`. `tests/` then holds only the runner and the CI scripts. The pack, `CLAUDE.md`, the CI workflow and `cucumber.js` are updated in the same pull request.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Who reads the scenarios, and what are they for? | They are the source and they run. Living documentation, with step definitions underneath. | The builder's call: that is what the method is about. A scenario kept beside a test can drift, and a document that can lie is not living. |
| 2 | How far does it go? | The whole suite, text pins included. A pin is written as a behavior the command promises, and the step does the `grep`. | The builder's call: one language for everything. The rule that keeps pins honest: a scenario names the behavior, not the wording. |
| 3 | How is it migrated? | Incrementally, one bash file per pull request. The old and the new run side by side until the last file is gone. Each migration shows a mutation check: the code is broken in several ways, and the old file and the new scenarios fail the same way. | Too large for one change, and a lost check can hide for weeks. The mutation check was used in #50 and showed that no check was lost. |
| 4 | Where do the pull requests go? | A long-lived base branch, `base/scenario-suite`, cut from `main`. Every pull request of the series targets it. Merging it into `main` is a last, separate pull request that the builder decides on. | The builder's call. `main` stays releasable while the suite is in two languages. |
| 5 | How is CI checked before a push? | A local script runs the same steps as CI and names the step that failed. | The builder's call: run the CI checks locally. CI runs on every pull request, base branch included, so the local run is a check before it, not a replacement. |
| 6 | Which language for the steps? | TypeScript, run through `tsx`, with a `tsc` gate in CI and in the local script. | The builder's review comment. A reference project of the builder's uses TypeScript steps with the same gate. `tsx` runs the steps but does not check types, so the gate is a separate step. A spike confirmed that `@cucumber/cucumber` 11 runs `.ts` steps with `NODE_OPTIONS="--import tsx"`. |
| 7 | Is `playwright-bdd` the runner? | No. `@cucumber/cucumber` stays. | `playwright-bdd` exists to drive a browser through Playwright fixtures. This suite has no browser. |
| 8 | Is the rename guard migrated? | No. It is dropped. | The builder's review comment. The rename is long done, and the old file said to drop it. The install addresses it also checked are still covered by the README and manifest tests. |
| 9 | What are the scenarios called? | Specs. The package is `bdd-skills-specs` now. The folders `tests/features` and `tests/steps` move to `specs/` in the last pull request of the series (E14). | The builder's review comment: in this method the `.feature` files are the specification, and "tests" frames them wrongly. Moving the folders now would touch every later migration pull request, so it waits until the bash files are gone. |

My calls, approved with the checklist: the runner is `@cucumber/cucumber` pinned to 11.3.0, with `tsx`, `typescript` and `@types/node` pinned beside it, as in fixture `c`. A private `package.json` and a lockfile at the repo root. Scenarios in `tests/features/`, step definitions in `tests/steps/`. The local CI script is `tests/ci_local.sh`, a name that `tests/run.sh` does not pick up.

## Existing users

Nothing changes in a user's project or in the plugin folder. `install.sh` does not copy tests. The version and the release flow do not change.

## First run

A contributor clones the repo, runs `npm ci` once, then `bash tests/run.sh`. Without the installed runner, `tests/run.sh` says what to do and stops. It never reports a pass for a run in which no scenario ran.

## Exclusions

- The plugin's own evals (`claude plugin eval` cases under `evals/`) and the real flow runs under `flows/`. Reason: they test a model, not the repo.
- Adding or changing what is tested. Reason: the migration keeps every check and adds none. New checks come in their own changes.
- A second runner such as bats. Reason: the point is one language.
- Any Node file in the plugin folder. Reason: the directory policy.

## Follow-ups after the series

Not part of the migration. Each is its own change, once the bash files are gone and `specs/` exists.

- **Message assertions for the release check.** `bdd:deliver` proposed scenarios that check the message a failing release check prints, such as "version 0.4.0 is not higher than 0.4.0 on main". The old bash test checked only the exit status, so the migration keeps to that, and the message checks wait. The builder's call. A rewording of a message would then fail a scenario on purpose.
- **A check for "no main to compare with".** The plugin's discovery found that the release check fails when there is no `main`. No old test covered it, so it was left out of the migration.

## Outcome of the last pull request (2026-11-12)

The series is done. No bash test file is left. E12 and E14 are carried out:

- `tests/features`, `tests/steps` and `tests/fixtures` moved to `specs/features`, `specs/steps` and `specs/fixtures`. `tests/` holds `run.sh`, `ci_local.sh` and `check_release.sh`. `cucumber.js`, `tsconfig.json`, `.claude/bdd-config.md`, `CLAUDE.md`, the README and the READMEs of `evals/` and `flows/` follow.
- `tests/run.sh` runs the scenarios only. The scenarios for the bash loop in `test-run.feature` are removed: the passing and failing cases keep one scenario each, and the case of a failing bash file is gone.
- `tests/lib.sh` and `tests/test_lib.sh` are deleted. `test_lib.sh` tested the old em-dash diff helper, which the repo-wide scan scenario replaced.

Decisions, with reasons:

| # | Decision | Reason |
|---|----------|--------|
| 1 | `check_release.sh` now holds the three release functions (`base_manifest`, `assert_version_bumped`, `assert_version_higher`) and the pass, fail and finish helpers. The release-version scenarios source it. It runs the checks only when run directly. | CI runs `check_release.sh`, and it sourced `lib.sh`. E11 said the release flow does not change. The behavior does not change, but the file now carries what it needs, so `lib.sh` can go. |
| 2 | `fixtures` moves with the scenarios. | Only the steps use them. `tests/` then holds only the runner and the CI scripts, as E14 said. |
| 3 | The old em-dash diff helper is not kept. | The scan in `plugin-repo-rules.feature` reads whole files and covers the same rule. |

The approach review that followed the migration is in `2026-11-12-approach-review.md`.

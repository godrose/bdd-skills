# Discovery: the deliver flow harness checks as scenarios

Input: `tests/test_flow_deliver.sh` (the source of every example), `tests/test_flow.sh` (the discover harness, for overlap), the scenario-suite pack (`2026-11-11-scenario-suite.md`), the pack `2026-11-11-deliver-flow-runs.md`, and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

The flow harness for deliver (`flows/`) plays a whole `/bdd:deliver` conversation with a headless session and counts rule breaks on the transcript. Migrate the checks of `tests/test_flow_deliver.sh` to scenarios. The scenarios run the real harness against a fake claude and a fake npm from `tests/fixtures`. A migration adds no checks.

## Overlap with `tests/test_flow.sh` (the discover harness)

- The guard rails (the harness is not in `tests/run.sh` or the workflows, and `flows/results/` is ignored) and the `TURNS=12` pin are asserted in both files. This migration keeps them once. The discover migration reuses the scenarios.
- The shared rules (look-first, one-question, plain-words, project-untouched) run in both. Here they run in deliver mode.
- one-question has no case in the deliver file, so no scenario here.
- The fake claude and fake npm are shared. The steps stay generic.

## Agreed examples (all from code)

Approvals (`flow-deliver-approvals.feature`)
- **E1** A `.feature` file after two approvals: held. After one approval, or after a reply that is not an approval: broken, and the detail names the file.
- **E2** "Fix the wording. Then yes, go ahead." counts as an approval.
- **E3** Two messages that ask for approval: held. A third ask: broken.

Report claims (`flow-deliver-report-claims.feature`)
- **E4** Report shape is held for a parked example with its section, and for a clean report without one.
- **E5** Report shape is broken for a parked example with no section, a section with nothing parked, and no line for E2.
- **E6** Never reported passed: broken for a pending scenario or zero scenarios with every example passed. Held for all passed, and for a pending scenario with the example parked.
- **E7** Parked not passed: broken for E3 listed and passed (the detail names E3), and for a range E1-E2 covering a passed E2. Held for a parked example not passed, and for no section.

Words and files (`flow-deliver-words-and-files.feature`)
- **E8** Plain words: held for a "For the developer" line and for a developer note naming a file. Broken for a path in the plain report.
- **E9** No readiness rule for deliver. look-first is still counted and held.
- **E10** Project untouched: a step file and the sample data held. `package.json` broken. The installed runner is not a change.

The saved run (`flow-deliver-run-record.feature`)
- **E11** The real `npm test` output is saved in the run folder.
- **E12** A report starting with "Delivered" ends the run: finished, 3 turns.
- **E13** `report.md` is titled "deliver, fixture c, story 1".

Compare (`flow-deliver-compare.feature`)
- **E14** Two reports side by side show both counts and mark only the rule that moved.
- **E15** No verdict word: pass, fail, regress, better, worse.
- **E16** A missing second report is a non-zero exit.

Install cache (`flow-deliver-install-cache.feature`)
- **E17** One install, into a cache keyed on a 16-character hash of the lockfile, copied into the run's project.
- **E18** A second run with the same lockfile does not install again. A changed lockfile does.
- **E19** A failed install exits non-zero, says "install", starts no session, leaves no cache. The default cache sits under `results/cache`.

Options (`flow-deliver-options.feature`)
- **E20** The first call is `/bdd:deliver` plus the story. It grants `npm test`, `node src/show.js` and `node src/show.js data/*`, and no `npm install` or `npm ci`. "Approved" reaches call 2.
- **E21** Turn cap 30 for deliver (`TURNS=30`) and 12 otherwise (`TURNS=12`). The README documents `--command deliver`.
- **E22** Not started by `tests/run.sh` or the workflows. `flows/results/` is ignored.

The fixture (`flow-deliver-fixture.feature`)
- **E23** Fixture c: lockfile, `@cucumber/cucumber` 11.3.0, two stories (story 2 mentions "stays in view"), approver persona says "Approved", one scenario.
- **E24** `show.js` prints "My loans", "Dune" and "overdue" from `data/loans.json`. No fixed page file. The config does not name one.
- **E25** `show.js` reads a given file under `data/` and shows a 3-day loan as not overdue. It refuses a path outside `data/` with a non-zero exit and a message naming `data`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How are the scenarios grouped? | Eight files: approvals, report claims, words and files, the saved run, compare, install cache, options, fixture. | Smaller files by what a maintainer would notice. The nine rules are spread over three files. |
| 2 | What is "the report"? | The run record and `report.md` (E11-E13). The report-shape rule sits with the report claims. | The builder approved this reading. |
| 3 | Where do the fixture checks go? | A sixth group, `flow-deliver-fixture.feature`. | They are in the old file. Dropping them would lose checks. The builder approved. |
| 4 | The `command -v node` guard? | Dropped. | The scenario run needs Node anyway. |

## Existing users

Nothing changes in a user's project or in the plugin. The harness is a maintainer tool and is not installed.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The scenarios use the fake claude and fake npm, so they need no login and no network. The new files run beside the bash file until it is deleted in the same pull request.

## Exclusions

- New checks, including a one-question case for deliver.
- The bash file's own helper DSL.
- Discover-only checks of `tests/test_flow.sh`.
- A real model run.

## Kept as they are

- Rule details are matched as fragments, not whole messages.
- The turn cap checks are text pins on `flows/run.sh`.

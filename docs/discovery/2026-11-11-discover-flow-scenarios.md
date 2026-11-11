# Discovery: the discover flow harness checks as scenarios

Input: `tests/test_flow.sh` (the source of every example), the deliver migration pack (`2026-11-11-deliver-flow-scenarios.md`), the scenario-suite pack, `flows/run.sh` and `flows/rules.pl`, and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

The flow harness for discover (`flows/`) plays a whole `/bdd:discover` conversation with a headless session and counts rule breaks on the transcript. Migrate the checks of `tests/test_flow.sh` to scenarios. They run the real harness (`run.sh`, `rules.pl`, `report.pl`) against a fake claude from `tests/fixtures`. A migration adds no checks.

## Overlap with the deliver migration

Not written again:
- `TURNS=12` pin (deliver scenario "The turn cap for discover is 12").
- Guard rails for `tests/run.sh`, the workflows and `.gitignore` (three deliver scenarios in `flow-deliver-options`).
- The "For the developer" line is not a break of plain words (deliver scenario in `flow-deliver-words-and-files`).

Same steps, new scenarios: rule held/broken/not counted, rule detail, file of the run contains, files exist, output mentions, the run fails, they hold N scenarios. The step code takes the command, the fixture and the story as parameters, and the deliver scenarios stay green.

## Agreed examples (all from code)

The saved run (`flow-discover-run-record`)
- **E1** Each assistant message and each reply is saved in turn order.
- **E2** A readiness line ends the run: finished, 2 turns.
- **E3** With no readiness line the run stops at the turn cap, is not finished, and the report says "did not finish".
- **E4** The persona card goes to the small model. Its reply is the next prompt.
- **E5** A relative output folder works.
- **E6** A run that got no answer is reported as "no answer" and is not scored.

Look first (`flow-discover-look-first`)
- **E7** Held for "What exists" first and for "What I found" first. Broken when a question comes before "What exists".

One question (`flow-discover-one-question`)
- **E8** Held for one question, for an open-questions list then one question, for numbered developer notes then one question, and when extra questions sit under "For the developer:". Broken for two plain questions.

Plain words (`flow-discover-plain-words`)
- **E9** Held for a plain message, a save offer for `docs/discovery/`, quoted literal values, and the vocabulary-check section.
- **E10** Broken for a path, an identifier in backticks, a page file, and a path in the candidate-exclusions section.

The pack end (`flow-discover-pack-end`)
- **E11** Held for a last message with the "Not ready. Still needed:" list and for "Ready for design". Broken with no readiness line, and for "Not ready." with no list.

The project stays as it was (`flow-discover-project-untouched`)
- **E12** A new file outside the pack folder is broken and named in the detail. A file in `docs/discovery/` is held.

The report (`flow-discover-report`)
- **E13** Counts, the rule that broke, run folder, message number, turns and seconds. No verdict word.

The fixtures (`flow-discover-fixtures`)
- **E14** Fixture a: one feature file, one scenario. Fixture b: no features or screens. Both have a story. Personas founder and pm exist.
- **E15** Fixture files with Windows line endings still run.

Start and guard rails (`flow-discover-start`)
- **E16** With no claude the harness exits non-zero, names claude and writes no output folder.
- **E17** `install.sh` does not mention flows.

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Nine small feature files named `flow-discover-*`, by what a maintainer would notice. | The builder asked for smaller files. |
| 2 | One ordinary-message baseline case per rule. | The old file checked each rule that way. |
| 3 | The turn-cap and `.gitignore` pins stay in the deliver files. | Not written twice. |
| 4 | A dated `removed:` line reverses the exclusion of the discover-only checks. | They are now in scope. |
| 5 | `tests/test_flow.sh` stays in place. The builder runs a mutation check against it, then deletes it. | Reverses the first proposal to delete it in this PR. |

## Existing users

Nothing changes in a user's project or in the plugin folder. The harness is a maintainer tool and is not installed.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The scenarios use the fake claude, so they need no login and no network.

## Exclusions

- New checks.
- The bash helper DSL.
- A real model run.
- Exact message wording beyond the fragments the old file matched.
- Deleting `tests/test_flow.sh` in this pull request.

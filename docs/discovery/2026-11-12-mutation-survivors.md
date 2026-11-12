# Discovery: the mutation survivors of the migrations

Input: the survivor lists in the pull requests that migrated the install, decisions, deliver flow, discover flow and evals checks (58 breaks that neither the old bash file nor the new scenarios saw), the code the breaks changed, and a dialogue with the builder.

## Story

A migration keeps behavior, so the breaks that both suites missed were listed and left. Triage them: which are real gaps, which are equivalent changes, which are only wording.

## Kind of check

A survivor is a change to the real code that no scenario fails on. It is a real gap if the changed code does something a user or a caller can see. It is an equivalent mutant if no input can tell the two versions apart. It is wording if only a message or a label changed.

## Result for the decisions script (25 survivors)

| Verdict | Count | What |
|---|---|---|
| Caught now by a new or stronger scenario | 23 | Schema errors for an unknown record kind, an unknown source kind, an effect with a missing key and a field that must be a list. A dangling reference failing the check. The `--manual-only-tag` option and the exit status for an unknown scope. A missing features folder. Fingerprint: a comment or tag line inside a scenario, spaces at the line ends, an id matched whole, a rule heading after a scenario. With a base ref: a scenario named in a new decision, an untracked feature file, an orphan and a conflict that were already there. A scenario removed by a later decision. The show page: a closed decision, a blocked scenario, a line break in a text. The message and the line number of the append check. |
| Equivalent mutant | 2 | `emptied log not caught` (the next condition on the same line catches an emptied log) and `new base file not skipped` (the files read are the ones that exist at the base, so the skipped case cannot happen). |

One survivor led to a defect. `check` requires `resolves` to be a list, and `show` read it only as a string. A question resolved through a list stayed in the "Still open" section. `show` now accepts a list or a string. A scenario failed before the fix.

## Not triaged in depth yet

Judged from the name of the break only. Each needs a look at the code before a scenario is written.

- **Install (2):** fixed. Legacy file removal (3 names) and the "skipped" listing line each have a scenario, and breaking either one fails it. See `specs/features/install-legacy-files.feature` and `install-own-command.feature`.
- **Deliver flow harness (15):** fixed or judged. Ten rule edges have scenarios in `flow-deliver-rule-edges.feature` (developer lines, allowed changes, the approval wording, ranges, failed and parked status, the Delivered line, the saved test output, code and file leaks in plain words). The config check now also refuses any `.html` or `pages` text. Not pinned, as wording: `report title changed`, `second report header renamed`, `persona changed`. Equivalent: `second report not required` (`compare.pl` fails on a missing file either way).
- **Discover flow harness (8):** fixed or judged. Four look-first openers, a pack file name in plain words and the story line endings have scenarios in `flow-discover-rule-edges.feature`. Equivalent, so no scenario: `bdd names allowed` (only a made-up name with an underscore differs) and `Not ready not known to pack-end` (the same text is read either way). The other three were already caught or are shared with the deliver scenarios.
- **Evals (8):** judged and fixed. Five break the README or the CI guide text (`CI guide drops EVALS_NIGHTLY`, `drops setup-token`, `README drops only for this case`, `drops usage`, `drops run.sh`). By the approach review these are phrase checks and are left. The other three are real and have scenarios: the lint script of the `design-lint-draft` fixture is run on small projects (`evals-lint-fixture.feature`: the ticket rule, tag on the line above, draft files, an outline, a tag with no number), and `evals/run.sh` is checked for the options it passes on, its exit status and the results it keeps, also after a failed run (`evals-run-script.feature`). `run.sh drops the tool call` was a break of a comment line, so the real call is now covered by those behavior scenarios.

## Existing users and first run

The only change to a shipped file is one line in `scripts/decisions.sh`, which `install.sh` copies into a project. A project that already has the script keeps its copy until the installer is run again. A log that uses the list form of `resolves` now shows its resolved questions as closed. Nothing else changes for users.

## Exclusions

- No change to the plugin text and no new rule in the script.
- No scenario for the two equivalent mutants.
- No message checks beyond the two that the break showed to be unchecked.
- The five README and CI guide phrase survivors stay. They are wording.

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Fix the decisions survivors first, in one change with the `show` defect. | They are the largest group, they run a real script, and one of them found a defect. |
| 2 | Strengthen two existing scenarios (the append check) instead of adding new ones. | The behavior was tested but one assertion was too weak to tell the two versions apart. |
| 3 | Leave the equivalent mutants. | No input separates them, so no scenario can fail. |
| 4 | Fix `show` for both forms of `resolves`. | The schema says list, and the older fixtures and the helper write a string. Both work now. |
| 5 | The other survivors stay a follow-up, with the verdicts above as a start. | Each needs a look at the code before a scenario is written. |

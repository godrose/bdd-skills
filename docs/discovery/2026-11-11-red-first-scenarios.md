# Discovery: the red-first and known-gaps checks as scenarios

Input: `tests/test_red_first.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

`plugin/commands/implement.md` states a red-first check (Phase 2.5), and `docs/known-gaps.md` lists what the plugin does not check. Migrate the checks of `tests/test_red_first.sh` to scenarios. A migration adds no checks.

These are checks of what the text says. Nothing runs. The scenarios say so under `Feature:`.

## Overlap with existing scenarios

None. `layout-listing.feature` checks that `plugin/README.md` mentions `known-gaps.md`, which is a different file from the `README.md` and `docs/README.md` the old test reads.

## Agreed examples (all from code)

The command text (`implement-red-first.feature`)
- **E1** The command names the red-first check and the heading `#### Phase 2.5: Red-first check`.
- **E2** The Phase 2.5 heading comes before the Phase 3 heading.
- **E3** It names the natural red and the forced red.
- **E4** It says what is not a red: an undefined step, a timeout, a setup or auth error, or a compile or type error.
- **E5** It never breaks a `.feature` or a data file, and it restores the original text with an empty diff.
- **E6** It reports a `Red-first:` line, and `not seen red` is an outcome.
- **E7** A scenario not seen red keeps the unautomated tag.
- **E8** It warns about a break left behind by an interrupted run.

Where the check lives (`implement-red-first-scope.feature`)
- **E9** `run.md`, `verifier.md`, `design.md` and `discover.md` do not mention red-first, in any letter case. One outline, four rows.
- **E10** The config template has no `red_first` row, in any letter case.

The gaps file (`known-gaps.feature`)
- **E11** `docs/known-gaps.md` exists and lists at least 5 gaps.
- **E12** Every gap has `**Not checked.**`, `**Why.**` and `**Closed when.**`.
- **E13** No two gaps share an id.
- **E14** `README.md` mentions `docs/known-gaps.md`, and the docs index mentions `known-gaps.md`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How are the scenarios grouped? | Three files: the command text, where the check lives, the gaps file. | Small files, by what a maintainer would notice. |
| 2 | One outline or four scenarios for E9? | One outline. | Only the file name differs. |
| 3 | Does the G5 line in `docs/known-gaps.md` change? | Yes. It names `tests/features/implement-red-first.feature` and not `tests/test_red_first.sh`. | The bash file is deleted after the builder's mutation check, and the line would point at nothing. |

## Existing users

Nothing changes in a user's project. Nothing under `plugin/` changes.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new files run beside the bash file until it is deleted.

## Exclusions

- Any new red-first or known-gaps check. Reason: a migration adds none.
- Deleting `tests/test_red_first.sh` in this change. The builder runs a mutation check against it first and deletes it afterwards.
- `deliver.md` also says red-first. The old test did not check it, so E9 leaves it out.

## Kept as they are

- E2 finds the first line that holds each heading, anywhere in the file.
- E12 counts lines holding each part and compares with the number of gaps. A gap with a part twice could hide another with none.
- A gap has three parts. The comment in the old file said four, and the test checked three.

## Frameworks and platforms

None. The scenarios read two text files and the repo's own Markdown.

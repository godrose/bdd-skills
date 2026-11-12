# Discovery: the deliver text checks as scenarios

> Superseded in part by `2026-11-12-approach-review.md`. Many of the phrase checks written here were dropped or trimmed afterwards. Kept as the record of the migration.

Input: `tests/test_deliver.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

`plugin/commands/deliver.md`, the trial record `docs/trials/2026-11-09-deliver-pm-session.md` and a few listing pages say what `/bdd:deliver` does. Migrate the checks of `tests/test_deliver.sh` to scenarios. A migration adds no checks.

These are checks of what text says. Nothing runs. The scenarios say so under `Feature:`.

## Overlap with existing scenarios

- `install-tool-permissions.feature` and `layout-directory-policy.feature` already check that `deliver.md` has no `allowed-tools` line. Not written again.
- `repo.feature` already checks that every discovery pack is in the docs index, which covers the line for `2026-11-11-deliver-no-developer.md`. Not written again.

## Overlap with bash files not yet migrated

Written once here. The later migrations of `tests/test_skills.sh` and `tests/test_plugin.sh` skip them.

- `test_skills.sh`: the missing-config stop and the template name in `deliver.md`.
- `test_plugin.sh`: `deliver.md` exists, the `/bdd:init` plugin note, no project-install path, no project-install skill name.

Not migrated here: the default `docs/out-of-scope.md` row in `deliver.md` (`test_skills.sh` keeps it).

## Agreed examples (all from code)

Shape and gates
- **E1** The command exists, has a `description:` and has no em-dash.
- **E2** The four steps come in order and name `bdd:discover`, `bdd:design`, `bdd:implement`, `bdd:run`.
- **E3** Missing config: it says so and stops, names the template, has the `/bdd:init` plugin note.
- **E4** The size gate says "say so in one sentence".
- **E5** Two approvals: the checklist first, then no `.feature` file before the go-ahead, which either person can give.
- **E6** `specify-only` stops after the go-ahead and says "specified and not implemented".

Stops, report, records
- **E7** A product decision is asked at once, one question, the answer recorded.
- **E8** A technical stop is parked: three failed tries, independent examples go on, the developer note.
- **E9** An approved scenario or its expected values are never changed to pass. The implementer is not invoked twice for a scenario.
- **E10** The report has passed, failed and couldn't-be-checked lines, a regression line, and goes into a pull request description.
- **E11** Couldn't be checked covers `@pending`, `manual-only`, `not seen red`, `zero tests` and "was not looked at in step 5". Regression names "a step whose code the increment changed".
- **E12** Records: decision line, out-of-scope file, `excluded:`, `removed:`, `revisit when`, never rewrite a line, leave the old entry, exclusions written at the checklist.
- **E13** Deleted features: local git only, shallow clone. `discover.md` has the same git line.
- **E14** The decision log without its script says "Nothing was recorded". A tracker key with no requirements-sync skill: "ask for the text".

Existing behavior and permissions
- **E15** Existing behavior is marked `from code`, and "already works".
- **E16** Permissions: pre-approves nothing, the person running it must approve, no resume file, nothing written on an early end.
- **E17** Plugin text rules: no project-install path, no project-install skill name.

Looking at the result
- **E18** Step 5 sits between Step 4 and the report.
- **E19** It says passing is not proof, names the screen, no-screen and declared-against-seen means, and does not run the suite again.
- **E20** A result that could be looked at and was not is never reported as passed. The report has a `Seen:` line and "not looked at".

A person with no developer
- **E21** The eight phrases of the no-developer pack.
- **E22** The risk section comes before the developer note, which no longer says "parked technical stops". The section is left out when nothing is parked.
- **E23** The no-developer pack holds "Decisions".

The trial record
- **E24** It exists, says who played the product manager, says it was not run through the command, has the two headings, and has no `/Users/` and no em-dash.

The listings
- **E25** `README.md` and `plugin/README.md` name `/bdd:deliver`. The docs index lists `2026-11-09-deliver.md` and the trial record.
- **E26** Four checks that are not about `deliver.md`: the README line "only if its first lines carry the installer", `### G9` in `docs/known-gaps.md`, and the handoff file with no `/Users/` and no `bdd-netcore`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | One file or several? | Nine small files named `deliver-*.feature`, by what a maintainer notices. | The old file has 22 groups. |
| 2 | New steps? | None. | Every check fits an existing step. |
| 3 | The path and skill-name regex checks | One outline with one literal per row. | The lists are fixed names, so a substring check is equal. |
| 4 | Overlap with existing scenarios | Not written again. (Replaces: written again.) | The scenarios already exist. |
| 5 | Overlap with bash files not yet migrated | Written once here. The later migrations skip them. (Replaces: written again, removed later.) | One home for each check. |
| 6 | Where does E26 go? | With the listings. | The old file put it there and a migration adds no checks. |
| 7 | The old file | Deleted after the builder's mutation check. | Same as #59 to #63. |

## Existing users

Nothing changes in a user's project. Nothing under `plugin/` changes.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new files run beside the bash file until it is deleted.

## Exclusions

- Any new check, and any change to `deliver.md`.
- The `allowed-tools` check and the no-developer index line (covered elsewhere).
- The default out-of-scope row check in `test_skills.sh`.

## Kept as they are

- Order checks find the first line that holds each phrase, anywhere in the file.
- Substring checks match anywhere in the text, as `grep -F` did.

## Frameworks and platforms

None. The scenarios read Markdown files of the repo.

# Discovery: the skills text checks as scenarios (PR 3 of 3)

> Superseded in part by `2026-11-12-approach-review.md`. Many of the phrase checks written here were dropped or trimmed afterwards. Kept as the record of the migration.

Input: `tests/test_skills.sh` (387 lines), `tests/features/`, `tests/steps/`, and a dialogue with the builder. Part 3 of 3 of `docs/discovery/2026-11-11-skills-text-scenarios.md`. Parts 1 and 2: `docs/discovery/2026-11-11-skills-text-scenarios.md` and `docs/discovery/2026-11-12-skills-text-scenarios-2.md`.

## Story

Move every check still in `tests/test_skills.sh` that no scenario holds to scenarios. About 113 checks, 109 after the review (decision 8). After this part the bash file is deleted, so nothing may be left behind.

## Kind of check

These are checks of what text says. Nothing runs. Each scenario reads a Markdown file and looks for a phrase, a missing phrase or a file. The migration adds no checks.

## Existing users and first run

- Existing users: no file under `plugin/` changes. A project that installed the plugin sees nothing.
- First run: `bash tests/run.sh` needs the runner from `npm ci`. Without it the run says so and stops.

## Agreed examples (PR 3)

- **E1** `skills-reconcile-commands`, `-flags`, `-codes`: the reconcile text runs the script and never edits, passes the six options, and names the error and info codes. 24 checks.
- **E2** `skills-reconcile-config`, `skills-triage-config`: a missing config stops, and the template is named. 4 checks.
- **E3** `skills-triage-phrases`, `-fragments`: the triage text keeps its approval rules, and shows the JSON fragments and the date form. 21 checks.
- **E4** `skills-readme-install`, `-init`, `-detect`, `-migration`, `-private`, `-phrases`: what the README says on install, init, detect, moving to the plugin, the private repo, and the other phrases. 54 checks.
- **E5** `skills-listings`: the dry-run doc, the packaging design doc and known-gaps G10 and G12. 4 checks. Dropped after review, see decision 8.
- **E6** `skills-init-text`: the init text on steps entries, IDE generation, the audit's closing line. 5 checks.

## Tally of the whole old file, by line range

Counts are by hand. The last line of the pull request description repeats them, checked against the final files.

| Old lines | Held by | Checks |
|-----------|---------|--------|
| 1-41, 48-63, 67-72, 90-102, 120-128, 160-166, 188-325 (except the lines named in this table), 346-384 | parts 1 and 2 | about 275 |
| 28, 66, 87, 312, 339 | skipped: em-dash scans in `plugin-text-rules` | 6 |
| 43-46 | E4 (3), skipped `## The flow` in `readme-order` (1) | 3 + 1 |
| 73-75 | E4 (4), skipped Optional config rows summary in `readme-folded` (1) | 4 + 1 |
| 76 | E5, dropped (decision 8) | 1 |
| 78-80 | skipped: `plugin-files`, `plugin-renames-and-text` | 2 |
| 81-86 | E1 (10), E3 (15) | 25 |
| 88 | skipped: `skills-template`, `plugin-renames-and-text` | 2 |
| 104-107, 130-132 | E4 | 11 |
| 109-111 | E3 | 6 |
| 113-119 | E1 | 14 |
| 136-140 | E2 (4), skipped deliver in `deliver-shape` (2), parts 1 and 2 (9) | 4 + 2 + 9 |
| 144-150 | E4 (11), skipped marketplace line in `readme-order` (1) | 11 + 1 |
| 154-157 | E4 (5), skipped `/bdd:init` in `readme-order` (1) | 5 + 1 |
| 170-173 | E4 (5), E5 dropped (1) | 6 |
| 176-184 | E4 | 12 |
| 230-231 | E5, dropped (decision 8) | 2 |
| 285 | E4 | 1 |
| 326-329 | E4 (1), E6 (2), parts 1 and 2 (4) | 3 + 4 |
| 332-333, 342-343 | E6 | 4 |
| 385-386 | part 1 (1), E4 (1) | 2 |

New: 109 (113 before decision 8). Skipped as an existing overlap in part 3: 15 (the lines above that say skipped, plus the em-dash scans).

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | The README is read with `the README` and `it contains:`. No new step. | The step set fits (see parts 1 and 2, decision 3). |
| 2 | Plain scenarios, not outlines, where a phrase has `<` in it. | An outline would read `<project>` as a column. |
| 3 | The short triage words (`open`, `change`, `question`, `approve`) stay as the old file had them. | A migration adds no checks and does not tighten them. |
| 4 | `reconcile` and `triage` each get a small config file, with two checks. | The old loop ran both with the other commands. The prefixes the builder named keep them apart. |
| 5 | The init text lines go in `skills-init-text`. | The builder approved the name. No named prefix fits them. |
| 6 | The builder deletes `tests/test_skills.sh` and edits `tests/run.sh`, `tests/ci_local.sh` and the docs that name it. This change does not. Reversal: it replaces the plan that the agent deletes the file. | The builder asked to do them. Until then the migrated checks run twice. |
| 7 | The builder's mutation check is the red proof. No mutation is run in this change. | The builder asked for it. |
| 8 | `skills-listings` is not written. Its four checks are dropped: the dry-run doc exists, the packaging design doc holds `/bdd:init --detect`, and G10 and G12 headings are in the known-gaps file. | A review of PR 3 said they test an implementation detail, not an outcome. They check that old working papers exist and that a heading is there, and no reader gets anything from that. This replaces the plan in E5 and the builder's "migration adds no checks" rule for these four. The wider question, whether phrase checks on prompt text are worth keeping, goes to the approach review. |

## Exclusions

- Deleting `tests/test_skills.sh` and editing `tests/run.sh`, `tests/ci_local.sh` and the docs: the builder does them.
- Checks the old file did not make.
- Any change to a file under `plugin/`.
- Scenarios for phrases that `readme-order`, `readme-folded`, `plugin-text-rules`, `plugin-files`, `skills-template`, `plugin-renames-and-text` and `deliver-shape` already hold.

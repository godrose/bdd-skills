# Discovery: `bdd:design` checks that a scenario asserts what its title claims

Input: the two trials of `/bdd:deliver` on a real project (`docs/trials/2026-11-09-deliver-pm-session.md`), a read of `plugin/commands/design.md` Phase 2, and a discovery dialogue with the builder, one question at a time.

## Story

A designer drafts scenarios, and each has a title. A title says what the scenario proves. A scenario can pass while its steps prove less than its title says. The audit in `design` checks that reused steps exist and what a reused `Then` asserts. It does not compare that with the title. The person approving sees a green-looking table and a title that promises more.

## Existing behavior (from the command)

- Phase 2 step 4 has Pass A (exact match), Pass B (paraphrase audit) and Pass C (assertion check). Pass C reads each reused `Then` step's definition and records what it asserts, then compares that with the scenario's data.
- Phase 4 shows a per-step audit table with an `Asserts` column. On a Pass C mismatch the designer flags the row and proposes two fixes, and the person chooses at the approval gate. The designer never changes fixture data or a step silently.
- Pass C already has rules for a definition that cannot be read ("assertion unknown") and for a step that has no definition yet ("assertion not checkable yet").
- Nothing compares a scenario's title with what its `Then` steps assert.

## Agreed examples

- **E1** A title names two things and the steps assert only one. The audit table flags it, offers two fixes (narrow the title, or add the missing assertion) and says which it prefers.
- **E2** A title names an exact value and the step only checks that something is there. It is flagged the same way.
- **E3** A title whose named things are all asserted gets no finding. The row shows that the claim matches.
- **E4** A step whose definition cannot be read, or that is new, gets "claim unchecked". The row says what was compared.
- **E5** Existing scenarios are not checked, even when the new ones reuse their steps.
- **E6** The designer never changes a title, data or a step itself. The person chooses at the approval gate.
- **E7** It works with no config row, and a fresh project sees the same table.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What does the first version cover? | Title against assertions only. | It is decidable from text and extends Pass C. The declared-state check needs knowledge of what the system does, so it stays in step 5 of `deliver` for now. |
| 2 | What does the designer do on a finding? | Flag it in the audit table with two fixes and a preferred one. The person chooses at the approval gate. | It is how Pass C works, and the designer never changes an approved claim silently. |
| 3 | Which scenarios are checked? | Only those drafted in this run. | Findings on old scenarios would pile onto a person approving one change. A project-wide audit is a separate feature (G10). |
| 4 | What counts as asserting less? | A named thing with no assertion, or a named exact value that a step checks only weakly. Not the reverse (extra assertions). | Pass C already records the strength of each assertion. Extra assertions are mostly harmless and would be noise. |
| 5 | Where does it sit? | A new Pass D next to Pass C in Phase 2, with a `Claims` column in the same audit table. | The evidence is in one place: title, claim and assertion together. A lint rule would need a lint row, which many projects lack. |
| 6 | When the assertion cannot be read? | Record "claim unchecked", flag it and do not guess. For a new step compare the title with the step's wording only, and say so. | Same rule as Pass C. Judging from wording is a possible opt-in mode later, not the default. |
| 7 | Can a project switch it off? | No. It is always on, with no config row. | It only adds rows to a table the person already reads. A row can be added later with a default of on, as a dated reversal, and it needs its own discovery. |

## Existing users

- A project that already uses `bdd:design` gets Pass D when it updates the plugin or re-runs `install.sh`. Its `.claude/bdd-config.md` needs no change, because there is no new row.
- A user's own command or skill with a similar name is not touched. Nothing is installed or deleted.
- Scenarios already in the project are not checked and not changed.

## First run

A fresh project with no config sees the same table with a `Claims` column. It has no step definitions yet, so every `Then` is new and the rows say "claim unchecked" with the wording compared.

## Exclusions

- A project-wide audit of every scenario: known gap G10.
- Judging from a step's wording when the definition is unreadable: a possible opt-in mode later.
- Flagging steps that assert more than the title says: too noisy.
- The declared-state check, and running examples against a real configuration: they stay in step 5 of `deliver`. A later discovery may move them.
- A config switch: it can be added later, default on.
- An eval of Pass D: a text test pins the rule. No eval runs a whole design flow with a weak title.

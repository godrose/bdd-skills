# Discovery: `bdd:deliver` keeps an untouched existing scenario out of the checklist

Input: real flow run 6 of `bdd:deliver` on fixture `d` (2026-11-12), the runs before it, a read of `plugin/commands/deliver.md` step 1 and the report, and the `report-shape` rule in `flows/rules.pl`. Three questions were put to the builder, one at a time. This pack records the answers.

## Story

When a project already has a passing scenario that nobody asked to change, the assistant should not turn it into a numbered example. It belongs in the Regression line of the report.

## Existing behavior (from the commands and the runs)

- `deliver.md` says the checklist is "a numbered list in plain words (`E1`, `E2` and so on), each marked confirmed". It says nothing about an existing scenario nobody asked about.
- The report has "one regression line" and one line per example. A numbered item with no report line is a gap.
- In run 6 the assistant added "E0: the existing 'Export all records' scenario keeps passing" to the checklist and gave it no report line. It appeared only in the Regression line. The `report-shape` rule counts every `E<number>` in the checklist, so it broke ("no line for E0").
- In runs 3 and 5 an existing scenario that matched an agreed behavior ("no filter, every record") was a numbered example and had its report line. That was correct, because the product manager had confirmed the behavior.

## Agreed examples

- **E1** A project has a passing scenario for a behavior the story does not touch. The checklist does not list it. The report counts it on the Regression line.
- **E2** An agreed behavior that an existing scenario already covers stays a numbered example, and the report gives it a line as for any example.
- **E3** An existing scenario that the change makes fail is not left on the Regression line as a count. The line names what used to be true and the decision made, as the report text already says.
- **E4** Every example in the checklist has a report line, so the `report-shape` rule holds.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Where does an untouched existing scenario belong? | In the Regression line only, never in the checklist. | The builder chose it. The checklist is the behavior the product manager described and confirmed. The Regression line already counts the scenarios that must not break. |
| 2 | Where does the rule live? | In `deliver.md` only, in step 1 where the checklist is asked for. | The builder chose it. The Regression line and the report belong to `deliver`. Standalone `discover` has no such line, so a rule there would point at nothing. |
| 3 | Does the harness get a new rule? | No. The `report-shape` rule stays. | The builder chose it. A rule that spots an existing scenario in prose would be a phrase check and miss other wordings. `report-shape` already shows the slip as a missing line. |

## Existing users

- A project that updates the plugin gets the new sentence in `deliver.md`. `.claude/bdd-config.md` has no new row.
- A project's own command with the same name is skipped by the installer, as now, and keeps its own text.
- Their scenarios, steps and checklists in earlier pull requests are not touched.

## First run

A fresh project has no existing scenarios. The checklist is the agreed examples and the Regression line says there are no earlier scenarios, as now.

## Exclusions

- `discover.md` and standalone `discover`: unchanged.
- A new flow harness rule: not added (decision 3).
- How the assistant tells "nobody asked about it" from an agreed behavior in a borderline case: left to its judgment. E2 gives the clear case.
- The `look-first` phrase check and the other harness items: separate.

## Not proven by this change

A flow run is a model run. One run cannot show that the text holds. The pins check that the text says it, and the real flow shows what the model did.

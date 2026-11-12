# Discovery: `bdd:design` checks the setup that a scenario depends on

Input: issue #41 (the second of its two small guidance changes), a read of `plugin/commands/design.md` (Phase 3 and the anti-patterns table), the saved eval runs that show empty-bodied `Given` steps, and a discovery dialogue with the builder, one question at a time.

## Story

A scenario can depend on state that another process provides: a configuration record, a seeded user, a deployed service version. `bdd:design` tells the designer to declare an empty-bodied `Given <prerequisite> exists` step for it, "intentionally a no-op". The step passes when the prerequisite is missing. The scenario then fails later, on a `When` or a `Then`, and the cause is hidden. Issue #41 asks that a test which depends on the setup checks it and reports a clear setup error when it is absent.

## Existing behavior (from the command)

- Phase 3 has a rule, "Informational Background step for out-of-band prerequisites": declare an empty-bodied `Given <prerequisite> exists`, and the body is a no-op. The anti-patterns table repeats it.
- Phase 2 has Pass A to Pass D. Pass C reads the definition of each reused `Then` step and records what it asserts. Nothing reads the definition of a reused `Given`.
- Nothing tells the person approving which prerequisites are assumed and not checked.
- No test or eval pins the old wording. The saved eval runs show projects whose `Given` steps are empty and pass.

## Agreed examples

- **E1** A scenario needs a seeded user that another process provides, and the test can look for it. The designer writes a `Given` step that looks and fails with a setup error that names the prerequisite and how to provide it. A missing user stops the scenario at the `Given`.
- **E2** A scenario needs a deployed service version that the test cannot query. The designer keeps an informational `Given` with an empty body and lists it in the proposal under "Assumed, not checked", with the reason.
- **E3** A reused `Given` step has an empty body and the scenario depends on the state it names. The audit flags the row and offers two fixes: (A) add a check that fails with a setup error, (B) accept it as informational and list it under "Assumed, not checked". The designer never changes the step silently. The person chooses at the approval gate.
- **E4** A `Given` that sets the state up itself (creates the record, logs in) is not affected.
- **E5** A reused `Given` whose definition cannot be read is recorded as "setup unchecked" and flagged. A planned step with no definition yet is compared with its text only. A step with a parameter that fits any value is recorded and passes. These are the rules of Pass C.
- **E6** In `specify-only` mode the check is written as a planned step like any other, and the proposal says a check is to be built.
- **E7** The check is read-only. It never creates the missing state, and a missing prerequisite fails the step. It does not skip the scenario or pass it.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What does the designer do for a prerequisite another process provides? | Check it when it can be checked. Keep an empty informational `Given` only when the test cannot see the prerequisite. | The builder chose it. A check turns a hidden later failure into a clear one, and the informational step still covers what cannot be seen. |
| 2 | Is the empty informational `Given` still allowed? | Yes, only for what the test cannot see, and it is listed under "Assumed, not checked" in the proposal. | The person approving should see what is assumed. A reversal: it replaces the rule "the body is intentionally a no-op", which allowed an empty body for any prerequisite. |
| 3 | Do reused `Given` steps get checked too? | Yes. A new Pass E reads each reused `Given` that the scenario depends on, flags an empty body and offers two fixes. | The builder chose it. The hazard is the same for an existing step, and Pass C already works this way for `Then`. |
| 4 | What does a missing prerequisite do? | It fails the step with a setup error. | A skip or a pass hides it, which is the defect in the issue. |
| 5 | What goes in the error? | The prerequisite by kind, and how to provide it. For example "Setup missing: a seeded user. Run the seed script." | A first-time runner needs the cause and the next step. The existing rule to name the prerequisite by kind stays. |
| 6 | Which steps does Pass E read? | Only steps reused in this run. | The same limit as Pass D. A project-wide audit is a separate feature (G10). |
| 7 | Is the check framework specific? | No. The text says "fails with a setup error" and leaves the way to the project's framework. | The plugin text must fit every framework in the config. |
| 8 | Where is "Assumed, not checked" shown? | In the proposal, after the Assumptions list, and as a section of the spec PR summary. Omitted when there are none. | The same place and rule as the Assumptions list. |
| 9 | Does `deliver` change? | No. A failed setup check is a failed step, and the run reports it as it reports any failed step. | The change is in the designer's guidance. The run rules already cover a failure. |

## Existing users

- A project that already uses `bdd:design` gets the new text when it updates the plugin or re-runs `install.sh`. Its `.claude/bdd-config.md` needs no change, because there is no new row.
- Scenarios and steps already in the project are not changed. An existing empty `Given` is flagged only when a run reuses it, and then only in the audit table.
- A user's own command or skill with a similar name is not touched.

## First run

A fresh project with no config and no steps has nothing to reuse, so Pass E has no rows. A new scenario that depends on out-of-band state gets a check, or an entry under "Assumed, not checked".

## Exclusions

- A project-wide scan for empty `Given` steps (known gap G10).
- A check written by the plugin without the person approving it. The designer proposes it with the scenarios.
- Changes to `implement`, `run` or `deliver`. They already write and run whatever step the designer approved.
- An eval of the new rule. It would need a model run. A text test pins the reversed wording and the new label, and the rule is not otherwise tested.
- A config row to switch it off. It only adds rows and a section to what the person already reads.

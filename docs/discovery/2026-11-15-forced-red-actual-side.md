# Discovery: the forced red breaks what the step observes

## Story

`bdd:implement` shows that a scenario can fail before it reports it as automated. When no natural red was kept, it forces one: it changes the expected value in the last `Then` step and checks that the scenario fails on that assertion. That proves the assertion runs. It does not prove that the assertion reads the behavior the scenario names. A step that compares against a value that is true for an unrelated reason, or that reads a stale element, still goes red when the expected value changes, and then passes for the wrong reason. The change is to force the red on the side that the step observes.

## Existing behavior

Phase 2.5 of `plugin/commands/implement.md`: a natural red kept in 2a ends the check. Otherwise one change is made in step code or in a helper, so that the assertion must fail, for example the expected value in a comparison. The red counts only when the scenario fails on an assertion in that step with an expected-versus-actual message. The file is restored and the diff against the original must be empty. The report has one `Red-first:` line per scenario, and a scenario "not seen red" keeps the unautomated tag.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| E1 | No natural red was kept, and the step reads something it can be made to read differently (a value, a field, a locator, a data key) | The forced red changes what the step observes and leaves the expected value alone. The report line is `Red-first: forced on the actual side, failed in <step>: <short message>`. |
| E2 | The actual side cannot be broken: the read is in generated code, in a shared client, or the step has no read of its own | The forced red falls back to the expected-value break. The line is `Red-first: forced on the expected side, failed in <step>: <short message>`. The scenario loses its unautomated tag as today. |
| E3 | A natural red was kept in 2a | The check is done as today. No break is made. |
| E4 | The break on the actual side points the read at something that does not exist, so the run times out or the step is undefined | Not a red. The break must give a different value. One smaller break is tried, then the expected side. |
| E5 | Neither break gives a red | `Red-first: not seen red: <reason>`, and the scenario keeps the unautomated tag, as today. |
| E6 | Any forced break | It goes in step code or in a helper only, never in a `.feature` file or a data file. The original text is restored and the diff against it must be empty. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | The forced red breaks the actual side first. Chosen by the builder. | It shows that the step observes the behavior, which a break of the expected value does not. |
| 2 | When the actual side cannot be broken, the expected-value break is the fallback, the tag is removed as today, and the line says "on the expected side". Chosen by the builder. | A project with generated or shared readers must still be able to automate a scenario, and the weaker proof is visible in the report. |
| 3 | The natural red is kept as today and is not checked again on the actual side. My call. | A scenario that fails at its assertion because the feature is missing already shows that the step reaches the assertion. |
| 4 | The order is natural red, forced on the actual side, forced on the expected side, not seen red. My call. | Each step is a weaker proof than the one before it. |
| 5 | The break never edits the application. It stays in step code and helpers. My call. | #102 made `implement` write test code only, and this keeps it so. |
| 6 | No config row. My call. | The check is part of the red-first phase, which has none. |

## Existing users

No config row and no new file. A project that adopted an earlier version sees the second kind of line change its wording, from `forced` to `forced on the actual side` or `forced on the expected side`. Their own steps and tags are not touched.

## First run

In a fresh project `implement` makes the same one break per scenario as before. The line in its report says which side was broken.

## Exclusions

- No edit of application code to break it.
- No mutation tooling in the user's project. This is one break by hand, per scenario.
- No re-check of a natural red.
- No change to `deliver` beyond what it already reads from the red-first line.
- Generated readers and shared clients take the fallback.

## Limits

- Choosing the actual side to break is the agent's judgment. The text gives examples, not a procedure for every framework.
- Nothing runs `implement` on a fixture and looks for the line (known gap G5 in `docs/known-gaps.md`). The spec checks the text.

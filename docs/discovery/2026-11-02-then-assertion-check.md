# Discovery: check what a reused Then step asserts

## Story

The designer reuses an existing step when its wording matches. A trial on a .NET project showed the gap. A new scenario reused a `Then` step that asserts an exact count of items. The new scenario's data had a different count, so the step failed. The reuse audit table marked the step as reused and fine. It had checked the words and not the claim the step makes. The mismatch showed up only when the implementer ran the test.

## Existing behavior (from the plugin)

- `commands/design.md` Phase 2 has Pass A (grep the text) and Pass B (paraphrases). Both compare wording.
- `commands/design.md` Phase 4 requires a per-step reuse audit table before approval. It marks steps as reconciled or intentionally new. It has no field for what a step asserts.
- `commands/implement.md` Phase 0 step 5 runs a paraphrase grep and stops if the wording should change. It has no rule for a reused step whose assertion does not fit.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Which reused steps get the check? | `Then` steps only. | A `Then` step makes a claim about the system. `Given` and `When` steps set up or act. "Same words, different claim" bites on `Then`. Revisit after real use. |
| 2 | What happens on a mismatch? | The designer flags it and proposes a fix: change the scenario data, or write a new step. It states a preference. The person chooses at the approval gate. | Changing fixture data can ripple into other scenarios. A new step adds code. Both are the person's call. |
| 3 | Does the implementer get a backstop? | Yes, one line in `implement.md`. If a reused step fails because its assertion does not fit, stop and report. Do not edit approved scenario data. | Covers specs approved before the check existed. Matches the rule against silent rewording. |

## Roles

- **Designer:** reads the step definition of each reused `Then` step and records the assertion in the audit table. Flags a mismatch and proposes a fix.
- **Builder or approver:** decides at the approval gate.
- **Implementer:** acts on the approved choice. Stops and reports if a mismatch appears later.
- **Verifier:** unchanged.

The audit table is the handoff artifact. It travels with the spec summary in `specify-only` runs.

## Edge cases (all confirmed)

1. Step defined in a shared or external library, or the definition cannot be read: mark "assertion unknown" and flag it. Do not guess.
2. Reused step is planned but not yet automated: no definition to read. Compare against the scenario text only and mark "assertion not checkable yet".
3. Step has a parameter such as `{int}`: the parameter fits any value. Record the parameter and pass.
4. Step definition is long or indirect: record the assertion that is visible and say if a helper was followed. If it cannot be told, treat as case 1.

## Candidate exclusions (all confirmed)

1. No check of `Given` and `When` steps.
2. No running of the suite at design time. The check reads code only.
3. No automatic data change or step rewrite.
4. No new config row.
5. No risk scoring. Every reused `Then` step gets the same check.

## Spec points

- **Existing users:** configs and project files are untouched. No new row, so `install.sh` and old configs behave as before. A project's own `bdd-*` skills are not changed.
- **First run:** a fresh project with no config sees no change. The check runs inside the designer's existing audit.
- **Exclusions:** see above. The check fits any project whose step definitions are readable text. It does not fit steps whose definitions live outside the repo (edge case 1).
- **Files that change:** `commands/design.md`, `commands/implement.md`, the tests that check the command text, and a plugin version bump to 0.1.6.

## Readiness

Ready for `bdd:design`. No open questions.

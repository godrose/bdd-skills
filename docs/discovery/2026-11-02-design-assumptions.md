# Discovery: list the assumptions behind vague acceptance criteria in design

## Story

A trial of `bdd:design --specify-only` on a .NET project used the AC "a finished experiment can be deleted too". "Finished" covers Completed, Failed and Cancelled in that system. The designer picked Completed and listed the others under exclusions. It did not flag the term before designing, as Phase 1 step 3 asks. The person approving saw only the result of the choice.

## Existing behavior (from the plugin)

- `commands/design.md` Phase 1 step 3 says: "Note ambiguities - if an AC is vague, flag it for the user before designing scenarios". It gives no test for what is vague and no place for the flag.
- `commands/discover.md` says: if the ACs are missing or vague, stop and ask. Discovery is the stage that asks. Design may run without it.
- The spec PR summary has these sections: Story to scenarios, Cases included, Cases deliberately excluded, New terms, Step status.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What does the designer do with a vague AC? | It does not stop. It designs with the narrowest sensible reading and states the assumption first in the proposal. | The Phase 4 approval gate already lets the person correct it. A blocking question adds a round trip, and cannot work in a headless run. Replaces the Phase 1 rule "flag it for the user before designing". |
| 2 | What counts as vague? | A term that names a category covering more than one distinct value the designer finds in the system or the existing features: states, roles, formats, units. | The model skipped a rule that said "if vague". A trigger it can check by recon is easier to follow. |
| 3 | Where is the assumption recorded? | At the top of the Phase 4 proposal, and in a new Assumptions section of the spec PR summary. | A reader of the spec PR has not seen the chat. |

Alternatives rejected: stop and ask before designing (blocking, no headless use), design every reading (inflates the spec), judgment only (the wording the trial ignored), a fixed list of words (misses domain terms).

## Edge cases (all confirmed)

1. No vague term: the proposal says "Assumptions: none". The summary omits the section.
2. A discovery pack settled a term: it is not listed again. Terms the pack left open are listed.
3. `specify-and-implement` mode: the list is shown in the proposal only. The approval gate is unchanged.
4. Recon cannot find the possible values: the term is listed as "values unknown, please confirm".
5. The person picks another reading at the gate: the affected scenarios and the list are updated.
6. Each entry has the term as written, the reading chosen, the other readings found, and where they were found.
7. Headless run: nothing blocks.
8. `discover.md` still stops and asks.

## Candidate exclusions (all confirmed)

1. No blocking question in design.
2. No new config row.
3. No list of trigger words.
4. No scenario per reading.
5. No decision-log record for assumptions.
6. No change to `implement`, `verifier`, `run` or `discover`.

## Spec points

- **Existing users:** their configs, features and earlier spec summaries are untouched. A summary written before this change has no Assumptions section, which reads as "none".
- **First run:** a fresh project sees the Assumptions line at the top of the first proposal.
- **Exclusions:** see above. The trigger is a judgment made from recon, so a missed term costs what it costs today: the choice is visible only as an exclusion.
- **Files that change:** `commands/design.md` and `tests/test_skills.sh`. No version bump, since the plugin tracks commits.

## Readiness

Ready. No open questions.

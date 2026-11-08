# Discovery: the red-first check in `implement`, and a known-gaps file

Input: a read of `commands/implement.md`, `commands/run.md` and `agents/verifier.md`, and the limits already recorded in this repo.

## Story

Two small changes, one pack.

- **A. The red-first check.** A builder runs `/bdd:implement`. A scenario that goes green may be green because its `Then` step never touches the behavior. The loop should see the scenario fail for the stated reason before it counts the green as proof.
- **B. A known-gaps file.** The plugin has real limits that are scattered over eval notes and chat. One file should list them, so a user can see what is not checked and a gap cannot be forgotten.

## Existing behavior (from the repo)

- `implement` runs the test after each group of steps. A group passes if at least one test ran and none failed. A run with no tests is not a pass.
- `implement` removes the unautomated tag (default `@pending`) only after the **verifier** reports PASS. "No tests ran" and "executed count unknown" are failures.
- `implement` does not edit approved scenario data and does not reword a reused `Then` step.
- Nothing in `implement`, `run` or the verifier asks whether the scenario was ever seen failing. A weak assertion or a reused step that checks nothing relevant can pass unnoticed. `design` has a Pass C assertion check, which reads step code. It does not run anything.
- `init` already ends its audit with a line saying what was not checked.
- The limits are known but not listed in one place: the `has-step-reuse-audit` eval misses some runs, nothing checks that `reports.feature` stays byte-identical, no command enforces its rules with hooks, and `design-lint-draft` is not run in CI.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Names | The file is `docs/known-gaps.md`. The rule is the **red-first check**. | Plain workflow words, like "assertion check" and "step-reuse audit". The builder chose both. |
| 2 | Where does the red come from? | Natural red if there is one, else a forced red. The first run of the scenario, before step code is written for it, is looked at. If a step fails on its assertion, that is the red. Otherwise the loop makes one temporary break after the groups pass. | Brownfield behavior often exists already, so a scenario may never fail by itself. |
| 3 | What if no red can be had? | Leave the unautomated tag on and report "not seen red: <reason>". The builder decides. | Same rule as "no tests ran": an unproven green is not a pass. |
| 4 | When does the forced red run? | Once per scenario, after every group has passed and before the verifier is dispatched. | The verifier's later full run is also the proof that the break was restored. |
| 5 | What counts as red? | A failed assertion in the step that was broken, with an expected-versus-actual message. An undefined step, a timeout, a setup or auth error, or a compile or type error does not count. | Those fail for reasons that say nothing about the assertion. |
| 6 | Where may the break go? | In step code or a helper that the `Then` step uses, for example the expected value in a comparison. Never in a `.feature` file and never in the project's data files. | `implement` must not edit approved scenario data. |
| 7 | How is the break undone? | The original text is held and restored, then the diff against the original is checked to be empty. If that cannot be confirmed, stop and name the file. | A left-behind break would be worse than no check. |
| 8 | What does the report say? | One line per scenario: `Red-first: natural, failed in <step>: <short message>`, or `forced, ...`, or `not seen red: <reason>`. | The evidence is visible, as with the `Groups` section. |
| 9 | When is the unautomated tag removed? | Only on verifier PASS and a red-first line that is not "not seen red". | Ties decision 3 to the existing tag rule. |
| 10 | A config row? | No new row. | The check is part of what "implemented" means. A row would make it easy to switch off the one thing that makes a green mean something. |
| 11 | Known-gaps shape | A plain list. Each gap has an id, what is not checked, why it is not closed, and how we will know it is closed. One test checks the shape and that the README links the file. | Several gaps have no cheap probe. Probes that fail when a gap closes can come later, per gap. |
| 12 | Initial gaps | Five. G1 the `has-step-reuse-audit` eval misses some runs. G2 nothing checks that `reports.feature` stays byte-identical. G3 no command enforces its rules with hooks, and evals sample behavior, they do not guarantee it. G4 `design-lint-draft` runs only by hand. G5 the red-first check has text tests but no eval. | Each is a known limit stated in the repo or this pack. |
| 13 | Release | No version bump here. A later release PR adds the changelog entry. | Feature PRs never bump the version. |

## Existing users

- **A project with automated scenarios:** nothing is re-checked. The check applies to scenarios that `implement` works on in a run.
- **A scenario where every step already exists:** it still gets the check, with a forced red on a reused `Then` step. The break is in a shared step for the length of one run and is restored before the next.
- **A project that is slow to run:** at most one extra run per scenario.
- **A project with its own `.feature` copy of a step text:** unchanged. The break never touches `.feature` files.
- **A user's own file with a name like `known-gaps.md`:** this repo's file is under `docs/`. Nothing is written into a user's project.

## First run

A fresh project has no automated scenarios. The first `implement` run reports the red-first line for each scenario. With no config change, nothing else differs.

## Edge and negative cases

1. The scenario fails on its assertion in the first run: that is the natural red, recorded, and no break is made.
2. The first run reports only undefined steps: it is not a red. The loop goes on, and a forced red is made after the groups pass.
3. The break does not turn the run red: report "not seen red: the break did not change the result". The tag stays.
4. The break turns the run red for another reason (a compile error, a timeout): not a red. Undo it, try once with a smaller break, then report "not seen red" if it still fails.
5. The test run is interrupted after the break: the next `implement` run checks the diff of the step files against the last commit and reports a left-behind break before it starts.
6. The break cannot be made safely, for example the assertion is inside generated code: "not seen red: assertion is in generated code".
7. The scenario has no `Then` step: report it and use "not seen red: no assertion step".
8. A reused `Then` step is shared with other scenarios: the break lasts one run. Other scenarios are not run while it is in place.
9. The working tree has uncommitted changes in the step file: the original text is held in memory by the loop, not taken from git.

## Candidate exclusions

Exclusions 1 to 5 follow from the decisions. Exclusions 6 to 8 were confirmed by the builder.

1. No mutation-testing tool and no automatic search for survivors. One break, chosen from the assertion.
2. No change to `run` or the verifier agent. The check is part of `implement`.
3. No change to `design`, `discover` or `triage`.
4. No edits to `.feature` files or project data files for the break.
5. No new config row.
6. No re-check of scenarios that are already automated.
7. No eval case in this change. The text tests come first. G5 records the missing eval.
8. The check does not prove a scenario is complete. It proves one assertion can fail.

## Tests to write first

Each must fail before the change.

- `implement.md` names the **red-first check** and says when it runs: first run before step code, and a forced red after the groups pass and before the verifier.
- `implement.md` says what counts as a red and what does not (undefined step, timeout, setup or auth error, compile or type error).
- `implement.md` says the break goes in step code or a helper, never in a `.feature` file, and that it is restored and checked.
- `implement.md` says a scenario with no red keeps its unautomated tag and is reported as "not seen red".
- `implement.md` says the report has one red-first line per scenario.
- `docs/known-gaps.md` exists. Each gap has an id, "Not checked", "Why", and "Closed when".
- `README.md` links `docs/known-gaps.md`.
- `docs/README.md` lists the new pack. That test exists already.

## Readiness

Ready for `bdd:design`. No open questions. Decisions 4 to 13, the edge cases and every exclusion are confirmed.

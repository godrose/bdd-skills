# Handoff: discovery for the design check

For the next session. Start with discovery, not a spec. The repo CLAUDE.md requires it: this is a new rule in an existing command.

## The question to discover

`bdd:design` checks that reused steps exist and what a reused `Then` asserts (Phase 2, Pass C). It does not check two things:

1. **A scenario asserts what its title claims.** A scenario named "A running experiment shows a dash" can pass while checking only that a field is empty.
2. **Every state the data declares can be observed.** A fixture can declare a status that the system changes at once. The scenario then passes and describes something that never happens.

Also in scope for the discovery: when a project has a real configuration next to a fake one, examples should run against both before they are called passed.

Run `/bdd:discover` on this by hand (one question at a time) and save the pack in `docs/discovery/`. Read `plugin/commands/discover.md` first.

## Evidence from the trials

Read `docs/trials/2026-11-09-deliver-pm-session.md` first. Three failures, all passing in the test run:

- **Declared against seen.** Two run-time scenarios named experiments Starting and Running. The data file declared those statuses. The sync service reverted them to Draft at once, because no job existed. The list showed Draft. Fixed by building the states through the real run.
- **Leftover row.** The details page kept an empty "Started" row that no scenario named. Found only by looking at a screenshot.
- **Fake against real.** Delete worked only against the fake data. The real data provider threw "not implemented". Found only when CI ran the same scenarios against a real database. The local run and the "Regression: all pass" line covered the fake configuration only.

Step 5 of `plugin/commands/deliver.md` ("Look at the result") is the patch at the end. The better fix is a check at design time.

## Questions the discovery should settle

- Where does the check live: a new Pass in Phase 2, a lint rule on the draft, or both?
- How does design learn what a data file declares and what the system will do with it? From the data file only, from the code, or by asking?
- Is "asserts what the title claims" decidable from text, or does it need a person? What is the false-positive cost?
- Does the real-against-fake check belong in design, in `bdd:run`, or in step 5 of deliver?
- What does this not fit: projects with one configuration, API-only projects?

## Files to read

- `plugin/commands/design.md` (Phase 2, Pass C, the anti-patterns table)
- `plugin/commands/deliver.md` (step 5, the Seen line)
- `docs/discovery/2026-11-09-deliver.md` (decisions 1 to 21; 17 to 21 came from the trials)
- `docs/known-gaps.md` (G7 no eval of a whole flow, G8 out-of-scope items not linked to a tracker)
- `tests/test_deliver.sh` and the eval layout, for how a new rule is pinned

## Open suggestions from the trials

Not done. Each is a small change, and each needs the size gate in `discover.md`.

1. Done (Step 0 in `discover`, `docs/discovery/2026-11-10-discover-look-first.md`): scan existing scenarios and screens before the first question.
2. Done in the same pack: ask where the shown state comes from, by finding the source in the code and asking the product manager only about the consequence.
3. Put the failing step before product code in every layer.
4. Offer Scenario Outline against separate scenarios by name.
5. Ask at the end which excluded items should become tickets (G8).

Also possible: say in the `verifier` description that it only runs tests and the type check. Do not rename the role before 1.0.0, because it is a config role.

## State and constraints

- Done after this note was first written: Pass D (the title check in `design`, `docs/discovery/2026-11-10-design-title-check.md`) and Step 0 in `discover`. Both are pinned by text tests only and have not been run in a live session (G11). `0.7.0` waits for that trial or for the maintainer's decision.

- `/bdd:deliver` is in PR #44 (branch `feat/deliver`, CI green). It is not merged and not released.
- Do not release `0.7.0` without the user. The directory review of `0.6.0` is still pending.
- Trial project: the .NET brownfield project the user trialled on (the user knows the path). Its delete and run-duration PRs are green. It has a script that runs the Server scenarios against real containers.
- The trials followed `deliver.md` by hand. Nobody typed `/bdd:deliver`. The product manager was the plugin author. A trial with a person new to the method is still to do.
- Plugin rules: plugin names only (`bdd:design`), no scripts or `allowed-tools` beyond Read, Grep, Glob and LS in `plugin/`. Run `bash tests/run.sh` before every commit. A new test must fail before the change.
- Do not name the trial project in plugin-facing text (G8 and the discovery pack were cleaned for this).

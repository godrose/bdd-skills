# `/bdd:init` and `/bdd:deliver` run on this repo, to migrate one test file

A record of one working session, kept as an example. The plugin was run on its own repo for the first time as part of the migration of the test suite to scenarios (`docs/discovery/2026-11-11-scenario-suite.md`). The file migrated was `tests/test_release.sh`, which checks the release version rules against throwaway Git repos.

## What this is, and what it is not

- A real headless run: `claude -p` with `--plugin-dir plugin` and `--resume`, one session for `init` and one for `deliver`. The product manager's part was played by the plugin author, one answer per question, relayed from a chat. The model never saw a persona card.
- The session cost about $3.50 notional over 10 calls, and `deliver` took 28 turns of its own.
- The product manager is the plugin author, who knows the method. This is not a test with someone new to it (known gap G11).

## What happened, in order

1. **`/bdd:init --detect` found the right values.** Test command, typecheck, features and steps folders, the framework config, and the shared state type (`World`, found by reading a step file). It proposed 8 rows and said which stayed unknown.
2. **It could not write the config.** A headless session cannot approve a write under `.claude/`: the shell asked for approval, and the file tools flag that folder as sensitive. Allowing the exact command or an exact path made no difference, since there is no prompt to answer. The plugin did not work around the block, and said what to do. The author copied the template and wrote the 8 approved values by hand.
3. **`/bdd:deliver`, step 1, stopped at once with a question.** The story said "a pull request that changes the plugin must not leave the version as it is". The plugin read the checks and found that the rule holds only for release pull requests, and that `CLAUDE.md` says feature pull requests never bump the version. It asked which was meant, with a recommendation. The story was wrong, not the code. This is the look-first rule doing its job.
4. **The checklist was built from the code.** Ten examples, each marked "from code" with its exact values, and two exclusions. The author dropped two: one that no old check covered (a migration adds no check) and one that a scenario in `repo.feature` already covers.
5. **The second gate** showed nine scenarios in plain words, a step-reuse audit and a choice between separate scenarios and an Outline. The scenarios asserted the failure messages, which the old checks did not. The author chose exit status only. Message checks are recorded as a follow-up.
6. **The report was honest.** Nine scenarios passed, red-first was shown by breaking the last step of each, and the report listed under "Not checked" that the type check and the whole test run were refused for approval. In its developer note it said that one example did not isolate the "plugin changed" check, because the scenarios ran both checks together.
7. **A mutation check found that gap.** Breaking each check in the code, the old bash test failed on all breaks, and the new scenarios missed two (the "plugin changed" check always passing, and ignoring changed commands). The old test had run the two checks separately.
8. **The plugin fixed it when told.** Given the finding, it changed the scenarios to run each check on its own. It then showed that breaking only the "plugin changed" check turns exactly one scenario red. A second mutation check agreed with the old file on all ten breaks.

## What this shows

- **Look first caught a wrong story,** and a product manager who knows the method still wrote one. The question cost one turn.
- **The report said what it could not check,** and named the equivalence gap before any outside check did. That is the "Not checked, and what it risks" section from `deliver` working in a real run, where the stops came from permissions and not from the planted case in the flow harness.
- **A passing scenario is not proof that nothing was lost.** The scenarios passed and still lost two checks. The mutation check against the old file found it. `deliver` has no step for "specify existing tests, and show that the new ones fail wherever the old ones did", so that check was the author's, outside the plugin.
- **The plugin proposed extra checks** (messages, a case with no `main`) because it saw them in the code. For a migration that is the wrong default, and a product manager has to say so. It listed them as examples and let the author drop them.

## Second run: the install checks?
?
The same flow on `tests/test_install.sh`: 25 examples approved, then 64 cases in 7 feature files after the author asked for a split. The mutation check (22 installer breaks, old file against new scenarios) agreed on every break that applied. Two things came out:

- **Both suites miss the same two things:** the removal of legacy command files, and the "skipped" line in the install list. Neither the old checks nor the new scenarios fail when the installer drops them. Listed as follow-ups, not fixed here, because the migration keeps behavior.
- **The report was honest about what it did not run:** it said it could not run `install.sh` by hand, because the grant was missing. It also counted 55 scenarios where there were 64, which the author caught on the run.

## Gaps and ideas this points to

- **`init` and a headless session:** a config write under `.claude/` cannot be approved without a prompt. It is a limit of the session, not a defect of the plugin, but `init` could say plainly that it needs an interactive session.
- **An "equivalence" mode for `deliver`:** when the story is "specify this existing behavior", the closing step could ask for a mutation check against the old tests. Not decided.
- **Grants for the closing checks:** the run did not have `bash tests/run.sh` and the type check, so the report had to say they were not run. A user would grant them in a real session.

## Limits as evidence

One session, one product manager who wrote the method, one existing-behavior story with no screen. It shows that the flow works end to end on a Cucumber and TypeScript project, and where it stopped. It says nothing about a new user.

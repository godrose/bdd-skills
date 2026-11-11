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

## Second run: the install checks
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

## Lessons learned

From one session and one product manager who wrote the method, so evidence and not proof.

### What the plugin did well

1. **Look first caught a wrong story.** The story said a pull request that changes the plugin must not keep the version. The plugin read the code and `CLAUDE.md`, saw that the rule holds only for release pull requests, and asked before writing anything. Without it, the scenarios would have specified a rule that reverses "feature pull requests never bump the version".
2. **The report was honest.** It said which checks it could not run and why, and it flagged the equivalence gap in its own developer note before any outside check did. This is the "Not checked, and what it risks" section in a real run, where the stops came from permissions and not from a planted case.
3. **"From code" marking kept the examples exact.** Each value came from the checks, not from the story.
4. **It took correction well.** Given the mutation finding, it changed the scenarios and proved the fix by breaking only one check. It did not argue and did not ask again for approvals it already had.

### What the plugin does not do

1. **A passing scenario is not proof that nothing was lost.** The first nine scenarios passed and still lost two checks. Only a mutation check against the old file found it, and that check was the author's. `deliver` has no step for "specify existing tests, and show that the new ones fail wherever the old ones did". This is the most useful finding.
2. **Its default is to add.** It proposed message assertions and a "no main" case because it saw them in the code. For a migration that is the wrong default, and the product manager has to say "no new checks".
3. **A headless session cannot write under `.claude/`.** No form of approval worked, because there is no prompt. The plugin refused to work around the block, which is right.
4. **Grants decide how much the report can claim.** The run had neither the whole test run nor the type check, so those went under "Not checked". A user would grant them in a real session.

### What the process taught

1. **Mutation checks earn their cost.** They found the equivalence gap here and were the proof in the earlier migration pull requests. Each migration carries one.
2. **Type and test gates caught the author's own mistakes.** A field that was never added, a scan that walked the installed dependencies, a package script that never landed. Checking that a gate fails when it should was worth the minutes.
3. **Line endings fail silently.** The working copy has Windows line endings, so several scripted edits did not apply and gave no error. Check every edit.
4. **Behavior is where the plugin adds most.** The rename and repo files were text checks, which the plugin fits poorly. The release rules were behavior, and its discovery added something there.

### Where the author fell short

- The plugin was not used until the builder asked. The first two migrations and the discovery pack were by hand, which missed the point of applying the method to itself from the start.
- The story given to `deliver` was careless about which pull request the rule applied to. The plugin's question was a fair correction of the author, not of the code.

### What this led to

1. From the next migration on, `bdd:deliver` is used from the start, on files with real behavior.
2. Whether `deliver` needs an "equivalence" step for specifying existing behavior is open. Two more files will say whether this was a one-off.
3. A line in `init` that it needs an interactive session to write the config is a small candidate fix.

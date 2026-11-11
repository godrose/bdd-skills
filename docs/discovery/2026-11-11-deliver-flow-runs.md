# Discovery: a scripted flow run for `bdd:deliver`

Input: known gaps G7 and G12, the discover flow harness (`flows/`), the pack `2026-11-10-discover-flow-runs.md`, the pack `2026-11-11-deliver-no-developer.md`, and a discovery dialogue with the builder, one question at a time. The builder acts as product manager, developer and solo developer: the plugin is the product and the method is applied to itself.

## Story

`deliver` is the longest command: two approvals, scenarios written, steps implemented, tests run, the result looked at, and a report. Its report shape and its new "Not checked, and what it risks" section are pinned only as text (G7, G12). The builder wants both to count as working only when a real headless run showed it.

## Existing behavior

- `flows/run.sh` plays `/bdd:discover` only. Turn 1 is fixed to that command. The tool grant is `Read Grep Glob LS Write Edit`, with no shell.
- Fixture A has features, steps and a `package.json` that runs `cucumber-js`, but no installed dependencies. A test cannot run on it today.
- A `discover` run took 1 to 1.5 minutes and about 1 dollar notional. A `deliver` run has no figure yet.
- Rules are counted by `flows/rules.pl`. The report gives counts, breaks and cost, with no verdict.

## Agreed examples

- **E1** A run starts `/bdd:deliver` with a story on a fixture project that has a working test runner. A small model plays the product manager from a persona card, answers each question and gives both approvals. The run ends at the report or at a turn cap.
- **E2** Before the first turn the harness installs the test runner from a cache. The cache is keyed on a hash of the fixture's lockfile, so a changed pin is a new cache. The first run needs the network, later runs do not. The model is never given an install command.
- **E3** The model's shell grant is the test command and a script that prints the fixture's page built from a loans file under the fixture's `data/` folder, so step 5 can look at the real page for more than one case. The script refuses any other path.
- **E4** Story 1 on the fixture runs cleanly. Its report has one line per agreed example, all passed, and no "Not checked" section.
- **E5** Story 2 on the same fixture has one example that cannot be checked in the run, because it needs a real browser. Its report says "couldn't be checked" for that example and has a "Not checked, and what it risks" section with a plain sentence and a "For the developer" line.
- **E6** The run counts nine rules. From `discover`: one question per message, plain words (now for the whole report), look first, and no file written outside the feature, steps, product code (`src/`), out-of-scope and decisions paths. New: no `.feature` file before the second go-ahead, no approval asked twice, the report has one line per agreed example with the "Not checked" section present exactly when something was parked, and an example that was not checked is never reported as passed. The ninth, added after the second real runs: an example named in the "Not checked" section is never marked passed.
- **E7** The never-passed rule is checked against the real test output saved in the run folder, not against the model's claim.
- **E8** Every message, reply, test output and the final report is saved in the run folder. The report of the harness gives counts per rule out of runs, breaks listed, turns, seconds and usage. It gives no pass or fail.
- **E9** One run per story is the first measurement. The pack says that it cannot show variance. The turn cap is raised for this command.
- **E10** A `--compare` option takes two earlier reports and prints each rule's count side by side, with the rules that moved marked. It gives differences and no verdict. Any saved report is a baseline.
- **E11** The harness runs only by hand. It is not in `tests/run.sh` and not in the nightly. Its tests use a fake claude and a fake install.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Shell or no shell? | A shell limited to two exact commands (the test command and a page script), on a fixture that can run tests. | Shows the whole path with a real report. The no-shell case is covered by decision 3. |
| 2 | Where does the runner come from? | The harness installs once into a cache keyed on a hash of the lockfile, then copies it into each run. The model never installs. | Repeated runs, and the network dropped out earlier. A key on the lockfile never goes stale. A real project already has its dependencies. |
| 3 | How is a parked stop produced? | Two stories on one fixture. Story 2 holds one example the run cannot check. | Deterministic, and the case G12 describes. A planted failing step would test the fix loop instead. |
| 4 | Which rules? | All eight in E6, and a ninth after the second runs (an example named in the "Not checked" section is never marked passed, which the builder approved). No judge model. | Each is a count. G7 and G12 name them. The honesty rule is the heart of G12. A regex catches identifier-shaped words only, which is a known limit. |
| 5 | How many runs first? | One per story. | Learn the cost and fix the checker before paying for repeats, as with `discover`. |
| 6 | How is a regression seen? | A `--compare` option puts two reports side by side and marks what moved. | The builder asked for a way to test that existing behavior did not regress. The harness runs by hand, so a quick comparison with an earlier report is what makes a rerun useful. No verdict, as in decision 6 of the `discover` pack. |

My calls, not yet agreed: the harness gets a `--command deliver` option and reuses `run.sh`, `rules.pl` and `report.pl` where it can. The fixture lives in `flows/fixtures/c` and reuses fixture A's story and feature files with a lockfile added. The persona gives "approved" at each gate.

## Existing users

Nothing changes in a user's project or in the plugin. The harness is a maintainer tool, not installed with the plugin.

## First run

A maintainer runs one script with a fixture, a story number and the command. Without a Claude login, `claude` on the path, or the network for the first install, it says so and stops. It writes only inside its run folder and the cache folder.

## Exclusions

- Flows of `design`, `implement` and `run` alone. Reason: `deliver` covers them in one run.
- Judging whether the questions were good, or the risk sentence is well worded. Reason: needs expert readers.
- A person new to the method (G11). Reason: still a model playing the product manager.
- The nightly and CI. Reason: cost and variance unknown.
- Three runs per story. Reason: decision 5.

## First real runs

One run per story on fixture `c`, a Haiku product manager, the default model under test. Counts only, so no run says anything about variance.

| | Story 1 | Story 2 |
|---|---|---|
| Turns | 6 | 7 |
| Seconds | 152 | 235 |
| Usage (notional) | $1.35 | $1.88 |
| Report | 4 of 5 examples "couldn't be checked", risk section present | 4 of 6 "couldn't be checked", risk section present |
| Rules broken | one-question (3 messages), plain-words (2 messages) | plain-words (2 messages), project-untouched (a scratch file left in the project) |

What the runs showed:

- **The new report section works.** Both reports kept the examples that could not be looked at as "couldn't be checked", never "passed", and the risk sentences were plain. The "For the developer" lines held the file names. This is the behavior G12 asks for, seen in a real run.
- **Story 1 was not clean.** It was meant to show the all-passed report. Every new example was "couldn't be checked", because the model's shell grant is the test command only, so it could not run or print the real page. The fixture's page is also a fixed file that nothing builds. The planted split between the two stories therefore did not happen. Open: how fixture `c` should let step 5 look at the page.
- **A checker error, fixed.** The `discover` rule "pack-end" (a Readiness line) was applied to `deliver` and broke on both runs. It now counts for `discover` only.
- **Real slips, not checker errors:** a message with a bold question heading and a second question line (restated, the same case as decision 10 for `discover`, but not yet covered for `deliver`), a "Files changed:" line naming files in the plain report, file names in the step audit table of the second gate, and a scratch file left in the project root after a look that needed an approval.
- **The cost of a run** is about $1.4 to $1.9 notional and 2.5 to 4 minutes. A run of three per story would be about $10.

## Second runs, after the page script

Fixture `c` gained a script that prints its loans page from sample data, and the model's shell grant gained that one command. Same setup, one run per story.

| | Story 1 | Story 2 |
|---|---|---|
| Turns | 7 | 7 |
| Seconds | 108 | 187 |
| Usage (notional) | $1.42 | $1.47 |
| Report | 1 of 3 examples passed, 2 "couldn't be checked" | 4 of 5 passed, 1 "couldn't be checked" |
| Rules broken | one-question (2 messages), plain-words (2 messages) | one-question (4 messages), plain-words (3 messages) |

- **The page was looked at.** In both runs the model printed the real page and read it. Story 1 passed its first example on that look. The first pair of runs could not do this.
- **Story 1 is still not clean.** The model wanted to look at two more cases and wrote its own one-off script for them. That needed an approval, which the run does not give. A fixed page script shows one set of data. Open: let the script take the loans as an argument, or let the model edit the sample data between looks.
- **Story 2 found a contradiction the rules do not count.** The report marks two examples "passed" while the Seen line says their pages were not looked at, and the risk section lists the same two as "seen only through the scenarios". `deliver.md` says an example whose result was not looked at is "couldn't be checked". None of the eight rules catches this, because the test output is all green. A candidate ninth rule: an example named in the "Not checked" section is never marked passed.
- **Run-to-run spread is large.** Seconds fell from 152 to 108 and from 235 to 187 with no change to the plugin. Two runs per story say nothing about a rate.
- **Slips again:** file names in the step audit table at the second gate, and a closing "what was added, and where" list that names files in the plain report.

## Third runs, after the ninth rule and the path argument

The page script now takes a loans file under `data/`. One run per story. Scored again after one checker fix (below).

| | Story 1 | Story 2 |
|---|---|---|
| Turns | 6 | 9 |
| Seconds | 133 | 157 |
| Usage (notional) | $1.20 | $1.66 |
| Report | 4 of 4 passed, after looking at the real page | 4 of 6 passed, 2 "couldn't be checked" |
| Rules broken | one-question (3 messages), plain-words (2 messages), report-shape | plain-words (3 messages) |

- **Story 1 gave the clean report.** All four examples were passed, and the model looked at the page with more than one set of data. This is the case the fixture was built to show.
- **A slip the shape rule caught.** Story 1's report carried the line "Not checked, and what it risks: nothing was parked." `deliver.md` says to leave the section out when nothing was parked. The text is clear, and the model wrote it anyway.
- **A checker error, fixed.** Story 2's product manager model wrote "yes, go ahead" at the second gate, and the rule only counted the word "approved". A plain "go ahead" now counts as an approval. The rule still breaks for a reply that is not one.
- **The ninth rule held on both runs.** In story 2 the model kept the unchecked example out of "passed" this time.
- **Totals so far:** six runs, $8.1 notional. The slips that came back every time are the one-question and plain-words ones, and each is about the second gate, where the design output carries a step table with file names.
- **Still open:** one run per story cannot show a rate. G7 and G12 stay open until the numbers are read over more than one run.

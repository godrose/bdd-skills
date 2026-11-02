# Discovery: a run that executes zero tests is not a pass

## Story

A trial on a .NET project showed it. A name filter matched no tests. The runner printed "No test matches the given testcase filter" and exited 0. Nothing in the plugin covers a run that executed nothing, so it can read as green. The same happened in practice when a new feature file was not linked into the test project: the new scenarios never ran.

## Existing behavior (from the plugin)

- `commands/run.md` Step 7 reports "pass count" on success. It has no case for a count of zero.
- `agents/verifier.md` reports `Total`, `Passed`, `Failed` and `Verdict: PASS | FAIL`. With no failures to list, "just say `Verdict: PASS`" is the natural reading.
- `commands/implement.md` steps 2a and 2d treat "the step passes" as success. Phase 3 relies on the verifier's PASS.

## Runner behavior varies

pytest exits 5, Jest and Playwright exit 1, `dotnet test` exits 0 with a warning, and Go, Mocha, RSpec, cucumber-js and Behat exit 0. Projects can also change the default with flags. So the exit code cannot define the meaning. Every runner prints a count or a "0 tests" line, so the plugin reads that.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What is reported when zero tests ran? | Never a pass. The verifier verdict is FAIL with the reason "no tests ran". `run` and `implement` report the same and stop. | Zero tests proves nothing. A third verdict would add a state every caller must handle. |
| 2 | How is "zero ran" detected? | No new config. Read the executed count from the runner's output or results (summary line, TRX, JSON report). Skipped tests do not count as executed. A runner message such as "no tests matched" counts as zero. | Every runner reports a count somewhere. A pattern row would change the template, install and old configs. |

## Edge cases (all confirmed)

1. The filter selects only unautomated-tag or manual-only scenarios: expected. Report "nothing to run: all selected scenarios are pending or manual-only". Not a FAIL.
2. All matched tests were skipped: zero executed. FAIL, and say how many were skipped.
3. The count cannot be found: say "executed count unknown". Do not call it a pass. The verifier gives FAIL with that reason.
4. An unfiltered run with zero tests: FAIL, "no tests ran".
5. List likely causes as hints only: the filter matched nothing, generate did not run or produced no output, a feature is not linked into the test project, the wrong project was selected.

## Candidate exclusions (all confirmed)

1. No new config row.
2. No change to a runner's flags, such as `--passWithNoTests`.
3. No retry. The verifier still reports the first outcome.
4. No minimum test count. One executed test is a run.
5. No change to how unautomated-tag and manual-only scenarios are excluded.

## Spec points

- **Existing users:** no new row, so `install.sh` and old configs behave as before. A project's own `bdd-*` skills are untouched. A project that relied on a zero-test run reading as green will now see a FAIL. That is the intended change.
- **First run:** a fresh project sees no change. The rule applies when a run executes nothing.
- **Exclusions:** see above. The rule fits any runner that prints a count. It does not fit a runner that prints no count (edge case 3).
- **Files that change:** `commands/run.md`, `agents/verifier.md`, `commands/implement.md`, the tests that check the text.

## Readiness

Ready for `bdd:design`. No open questions.

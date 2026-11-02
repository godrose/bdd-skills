# Discovery: group steps by risk so the implement loop needs fewer runs

## Story

`implement` Phase 2 runs the scenario after each step and again after each fix. The loop exists for UI work, where each step's selectors come from the page state the previous step left behind. A trial on a server-side .NET suite with fixed delays took many runs. A full run of that suite takes about 3 minutes for 8 tests. The scenario filter was already narrow, so the cost was the number of runs, not their scope.

## Existing behavior (from the plugin)

- 2a runs `prepare`, `generate` and `test` for the scenario. A passing step moves on to the next step.
- 2d reruns after each fix. The cap is 3 retries per step.
- A run only reveals the first failing step, because later steps do not execute.
- The approved spec's Step status table and the design audit table already mark each step as existing (automated), existing (not yet automated) or new.
- `design` Pass C records what a reused `Then` step asserts.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What does the loop run per iteration? | A group of steps, not always one step. | Fewer runs when steps are cheap to write. |
| 2 | How are groups formed? | By risk. Each new step is classified low or high. Low steps accumulate. A high step closes the group. | A run only reveals the first failure. Closing a group at a risky step wastes no guessed code after it. One rule covers UI and non-UI projects, because UI steps that touch new elements classify as high on their own. |
| 3 | What happens when a group fails? | Fix the failing step, then split the rest of that group in half and run each half. | A wrong guess costs one run and then narrows. There is no growing back. |
| 4 | Where is the setting? | A new optional `step_batch` config row. `auto` is the default and means the risk-based grouping. `1`, a number `N` or `all` are fixed and skip the analysis. | A project that knows its suite can opt out. Each value means one thing. |
| 5 | Is the plan approved? | No. It is printed once before the first run (step, class, reason, group). The run does not wait. | Keeps the loop moving. The person can read it and interrupt. |

Alternatives rejected: keep step by step everywhere (little change in runs), batch non-UI projects only (needs a separate UI rule), halve and double the size (ignores evidence about the steps), a time threshold (a number to tune), ask the person each time (friction).

## Classification (two classes)

- **existing:** a step definition already exists, or the Step status table says so. No work and no run.
- **low:** a new step whose body only composes existing page objects, helpers or client calls.
- **high:** a new step that needs a new element, endpoint, client method or fixture; asserts data not seen before; or consumes output an earlier step produces at run time. When unsure, classify high.

The keyword (Given, When, Then) is a tie-breaker only.

## Edge cases (all confirmed)

1. No new steps: no grouping, run once.
2. One new step: one group.
3. A step judged low fails: fix it, then split the rest of its group in half. The 3-retry cap per failing step still applies.
4. Every step judged high: groups of one, which is today's behavior.
5. Unsure about a step: classify high.
6. Steps from an approved spec: read the Step status table to skip existing steps. The plan lists them as "existing, no work".
7. Shared Background steps are treated like any other step.
8. Fixed values: `1` is step by step. `N` is N new steps per run. `all` is one group. An unknown value is treated as `auto` with a one-line note.
9. The plan is printed once before the first run.
10. `prepare` and `generate` still run on each iteration. The final verifier dispatch is unchanged.

## Candidate exclusions (all confirmed)

1. No run-time measurement and no time threshold.
2. No numeric scoring.
3. `/bdd:init --detect` does not fill the row.
4. No change to the retry cap, and no parallel runs.
5. No change to `design`, `run` or the verifier.

## Spec points

- **Existing users:** an old config without the row behaves as `auto`. `install.sh` reports the row as missing, with its default. Their project files are untouched.
- **First run:** a fresh config from the template has the row empty with an `(optional ...)` note, which counts as `auto`.
- **Exclusions:** see above. The classification is the model's judgment, so it is heuristic, and a misjudged step costs one extra run.
- **Files that change:** `commands/implement.md`, `bdd-config.template.md`, `install.sh`, `README.md`, `tests/test_skills.sh` and `tests/test_install.sh`. No version bump, since the plugin tracks commits.

## Readiness

Ready for implementation after the design is approved.

# Dogfood: the plugin on the .NET project (2026-11-04)

Input for discovery, not a spec. Each finding is a question for the plugin, with the evidence from a real brownfield project.

Project: a .NET project (SpecFlow, xUnit, .NET 10, Server and EndToEnd specs, one config committed before the plugin existed). Plugin: `main` at `2c4669f`, loaded with `claude --plugin-dir`.

## What was run

1. `/bdd:init --detect` on a project that already had `.claude/bdd-config.md`.
2. `/bdd:reconcile` on the same project.
3. A manual audit of the new `@real-executor` feature and its four outcome steps, using the plugin's step-reuse and scenario-style rules.

## Findings on the plugin

### 1. `init --detect` never audits existing values

The config had no `<...>` rows, so the command stopped at "no placeholder". The config was still wrong:

- header said `.NET 6.0`, the project is `net10.0`
- `config_file` pointed at `specs/specflow.json`, which does not exist (the real one is next to the features)
- the Skill Roles table named the old local `bdd-scenario-design`, `bdd-implement-scenario` and `bdd-verifier` instead of `bdd:design`, `bdd:implement`, `bdd:verifier`
- the `test` row ran every scenario, including ones that need a stack the fake run does not have

Question: should `--detect` also check existing values against the disk and report the ones that do not resolve? The rule "never change a row that has a value" can stay. Only the report is new.

### 2. The leftover check misses old installs

The `grep -l "^# Source: ..."` found nothing, because the installer's older copies have no `# Source:` line. Two of the three leftovers were not covered by the name rule either (`bdd-scenario-design`, `bdd-implement-scenario`, the old names of `design` and `implement`). The only proof they were installer files was a comment in `.claude/.gitignore` ("installed from https://github.com/godrose/bdd").

Question: should the leftover check also read `.claude/.gitignore` for the installer header, and list the old command names (`bdd-scenario-design`, `bdd-implement-scenario`)? In this run the model first called two of them "your own skills". That was wrong, and a user could act on it.

A second lesson: the plugin is not installed in most sessions yet (it loads only with `--plugin-dir`). The project copies are then the only skills a normal session has. In this run they were deleted and had to be restored. The report should say that the copies are safe to delete only after the plugin is installed for that project, and that the Skill Roles table should keep naming the local skills until then.

### 3. `reconcile` is no use without a decision log

With no `decision_log` row it stops at "the log is off". On a brownfield project that is the normal state, and nothing is left to run. The scenario-style audit still found real problems (below).

Question: is there a log-free mode, or should `design` offer an audit entry point that takes existing features instead of an AC?

### 4. Multi-project repos

The config covers `Features.Server` only. The repo also has `Features.EndToEnd` and `Features.Infra`. The "pick the project" step in `init --detect` never ran, because the command stopped earlier. Not tested.

## Findings on the scenarios (what a review should catch)

All fixed in the .NET project and checked against the real executor stack.

| # | Finding | Fix |
|---|---------|-----|
| 1 | Same wording, opposite role: `When ... starts running` drives the fake job, `Then ... is running` observes the real one | one step: `Then The experiment '..' reaches the '..' status` |
| 2 | `is cancelled` also asserted the job was cancelled, hidden in the code | renamed `is cancelled together with its job` |
| 3 | Three near-identical wait steps (`completes`, `is running`, `is cancelled`) | merged into the status step |
| 4 | `Bad input` asserted a table of three experiments, two of them unrelated | asserts the one experiment |
| 5 | The table step reads once, with no polling, so a late failure would flake | the status step polls |
| 6 | The expected `11` came from hidden test data | the title says `Adding 5 and 6 ... result 11` |
| 7 | The `@real-executor` tag and its second run were not in the config | added to Project-Specific Notes |
| 8 | The config `test` row had no `Category!=real-executor` filter, so the fake suite failed 3 scenarios that need the executor stack | filter added, fake suite 11 of 11 |

Not done: a scenario for `MultiplyNumbers`, and a check of the failure reason for `Bad input`.

Findings 5 and 8 are the ones a static review would not have found. They came from running the suites.

## Evidence

- Baseline before changes: 11 simulator scenarios and 3 executor scenarios passed.
- After the feature edit and before the step edit: 3 of 3 failed, "No matching step definition". This is the red run.
- After: 3 of 3 pass. Strict typecheck on the fake config: 0 warnings, 0 errors. Fake suite with the filter: 11 of 11.
- Mutation: expecting `Completed` for `Bad input` fails with "Expected lastStatus to be Completed ... but Failed". The guard can fail.

## Questions to take into discovery

1. Does `--detect` report existing values that do not resolve?
2. Does the leftover check cover old installs (no `# Source:` line, old command names, `.gitignore` header)?
3. What does `reconcile` or `design` offer when there is no decision log?
4. Should the review rules name the hidden-assertion and same-wording-opposite-role patterns? They were the most useful findings.

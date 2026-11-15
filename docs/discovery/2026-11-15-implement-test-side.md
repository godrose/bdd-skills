# Discovery: implement writes test code, deliver builds the feature

## Story

`bdd:implement` has two meanings since 0.7.1. It makes scenarios executable (step definitions, page objects, helpers), and it changes the application so a scenario goes green. The second is not this plugin's expertise, and the directory already has plugins for it (`feature-dev`, `superpowers`). The builder wants `implement` back to the test side, and `deliver` to be the one command that can build the feature, with the `feature-builder` role as the way a company brings its own way of writing code.

## Existing behavior

- 0.4.0 to 0.6.0: `implement.md` said "execution only" and named step definitions, page objects, helpers and support code. Application code was not named.
- `deliver` (#44, 2026-11-10) invoked `implement` per scenario and then ran the scenarios. Its runs built the feature, and the text only hinted at it.
- 0.7.1 (#95): `implement` 2c and `deliver` Step 4 both say they build the feature, with the optional `feature-builder` role and a skill named in the request. The same rule is written in two files.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| E1 | `implement` is run on its own. The step code is right, the assertion fails, and the feature is missing | It edits no application code and asks nothing. It reports the example as red for the right reason, says the feature is missing, and names the next step: run `/bdd:deliver`, or build it and run `/bdd:run`. |
| E2 | The thing the scenario names exists in the system, and the locator or call is wrong | A step problem, fixed in step code as before. |
| E3 | The thing the scenario names (page, element, route, field) is not in the system at all | A missing feature, not a step problem. The step is written as the scenario words it, with the project's locator conventions. The run fails at that step, and the report is as in E1. |
| E4 | The feature exists, and the step needs a test hook in the application: `data-testid`, an accessible label or similar, with no change in what the application does | `implement` adds the hook itself. |
| E5 | E4 on the default branch | It creates a branch `bdd/<story-slug>`, says so in one line with the name, and goes on. |
| E6 | E4 on a branch that is not the default | It stays on that branch and says nothing about branches. |
| E7 | The change would alter what the application does | It is not a hook. It is the feature: E1 on its own, the builder under `deliver`. |
| E8 | `deliver`, `build_order` is `all-first`, or the row is absent | `implement` automates every approved scenario. Then one build covers all the red examples together. Then the run, and a loop back to the builder within the existing cap. |
| E9 | `deliver`, `build_order` is `per-scenario` | Automate, build and run one scenario, then the next. |
| E10 | `deliver` is run with the flag for the build order | The flag wins over the row for that run. |
| E11 | A `feature-builder` row is set | `deliver` uses it for the build. `implement` on its own does not read it, and its report adds one line: run `/bdd:deliver` and it will use that skill. |
| E12 | The request names a skill for the application code | `deliver` uses it for that run, as today. `implement` on its own does not use it, and gives the line of E11. |
| E13 | No `feature-builder` and no skill named | `deliver` builds the feature with the smallest change that turns the scenarios green, as today. |
| E14 | `design` invokes `implement` after the go-ahead | The same as `implement` on its own. `deliver` does not invoke it again for that scenario (existing rule). |
| E15 | The scenario itself looks wrong | A product decision, asked, as before. An approved scenario or its expected values never change to make a check pass. |
| E16 | `workflow_mode` is `specify-only` | No implement step, so nothing is built. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | `bdd:implement` writes test code only. It never builds the feature. This reverses decision 1 of `2026-11-13-feature-builder-role.md` ("both build it") and replaces the "Building the feature" paragraph in `implement.md` 2c. | A command with two meanings of "implement" confuses its users. Application code is not the plugin's expertise, and the directory already has plugins for it. |
| 2 | `deliver` is the one command that builds the feature. It uses the `feature-builder` role when set, a skill named in the request for that run, and builds it itself when neither is there. Decisions 2, 6 and 9 of the earlier pack stand for `deliver`. | The README sends a newcomer to `deliver` first. Stopping at red scenarios would be a poor first run. |
| 3 | The line between a step problem and a missing feature: after exploring, a missing feature is a thing the scenario names that is not in the system at all. A wrong locator or call for something that exists is a step problem. The builder's rule. | `implement` exploring the real system is test expertise. It also removes the case where "locator not found" meant two things. |
| 4 | `implement` may add a test hook to the application (`data-testid`, an accessible label or similar) when it does not change what the application does. Anything that does is the feature. The builder's rule. | A hook is part of making the scenario executable, and it is a small, safe edit. |
| 5 | One rule for every application edit, from `implement` and `deliver`: on the default branch, create `bdd/<story-slug>` first and say so in one line. On another branch, stay. Never a worktree. The name and the worktree are my call. This extends decision 3 of the earlier pack (no approval gate) and turns the README's "work on a branch" advice into an action. | The end user expects the plugin to be autonomous, and has to know what it did. |
| 6 | A new Workflow row `build_order`: `all-first` (default) or `per-scenario`, with a flag on `deliver` that wins for one run. An absent row means `all-first`. The names are my call. | From the builder's experience the best order varies. A row plus a flag is the pattern of `workflow_mode`. |
| 7 | The build rule is written once, in `deliver`. The copy in `implement` 2c goes. | The drift risk named when #95 merged. |
| 8 | The checks are contracts between files and reversed decisions, not phrases of prose: the template has the `build_order` row, `deliver.md` names the role, the order and the flag, and `implement.md` no longer says it builds the feature. | The approach review of 2026-11-12. |

## Existing users

The builder says there are no users yet, and no config needs an edit. A config with a `feature-builder` row keeps working, now read by `deliver` only. A config without a `build_order` row behaves as `all-first`. Files of a project with similar names are not touched.

## First run

A fresh project with no config. `/bdd:deliver` on a story: if the project is on `main`, it creates `bdd/<story-slug>` before the first application edit and says so. It builds the feature with the default. `/bdd:implement` on its own for a new feature ends with scenarios that are red for the right reason, and the next step named.

## Exclusions

- No rename of `implement`. The name stays, and the meaning narrows to what the first line of the command always said.
- No approval before an application edit. The branch is the safety net.
- No worktree creation.
- `init --detect` does not propose the `feature-builder` role here. Still a follow-up.
- No change to `design`, `discover` or the verifier, except where they name the old behavior.
- Not tried: a real company skill, and a skill that asks its own question.

## Open

- The release number. It is a behavior change, and the builder chooses it.

## Result of a real run (fixture c, story 1, deliver, default order)

One run, 4 turns, 104 seconds. All nine harness rules held, no breaks, 4 of 4 scenarios green at the end. The build was done by `deliver` and not by a separate skill: `src/pages/loans.js` and `src/jobs/markOverdue.js` changed, and the steps file got three new steps. The developer note listed the application files and the test code separately, and said that E1 and E2 failed first because the page had no notice, which is red for the right reason. The project is not a git repository, so no branch was made, and the agent said so in one line.

Not shown by this run: the transcript keeps only the text of each turn, so the order of the calls is not visible. The harness runs `deliver` and `discover` only, so `implement` on its own was not tried. The fixture has no `build_order` row, so only the default was used, and the branch rule met no git repository.

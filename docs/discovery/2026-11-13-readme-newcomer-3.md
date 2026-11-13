# Discovery: the README for a newcomer, third part (which path, branch, runner check, scenario data)

Input: the third goldfish run on the README after `2026-11-13-readme-newcomer-2.md`, `README.md`, `plugin/commands/deliver.md`, `plugin/commands/design.md` (Pass E and "Check the setup the test depends on"). One question was asked: which path a developer should take first.

## Story

A developer who reads The flow sees the three commands and `/bdd:deliver` and cannot tell which to pick. They also do not know whether to work on a branch, how to try the runner, or how a scenario's starting state gets created in their app.

## Existing behavior

- The flow gives "For an individual builder" (three commands) and "For a product manager with a developer watching" (`deliver`). A developer is told neither is theirs.
- The runner check in Before you start says to write a `Given` step that does nothing, with no snippet and no place for the file.
- The README does not say the plugin edits the project's files, or that a branch is wise.
- The README does not say who creates the state a `Given` step needs ("an order that has not shipped").

## Agreed examples

| # | Finding | What changes |
|---|---------|--------------|
| E1 | Which path | Two lines at the top of The flow: first run or one conversation, use `/bdd:deliver`. Stop and review between steps, or work with `specify-only`, use `/bdd:discover`, `/bdd:design` and `/bdd:implement`. |
| E2 | Runner check | The check is "follow the runner's own getting-started page until its example passes". The do-nothing step is dropped. |
| E3 | Branch | Before you start lists a branch: the plugin edits tests and application code, so work on a branch and read the diff before you merge. |
| E4 | Scenario data | What you get says each `Given` step needs code that puts the app in that state. `implement` writes it, using how your tests and app already create data. State that something else provides (a seeded user, a deployed service) gets a step that checks it is there and fails with a setup error. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | A short chooser with `deliver` for a first run. Chosen by the builder. | `deliver` is one conversation with two approvals, and it matches the demo at the top of the README. The "product manager" line is a typical user, not a limit. |
| 2 | The runner check points at the runner's own getting-started page. My call. | A do-nothing step is different in every runner, and a snippet for each would age. |
| 3 | Say "work on a branch" and do not add an approval gate. My call. | Decision 3 of `2026-11-13-feature-builder-role.md` has no extra approval before application code. A branch is the user's own safety net. |
| 4 | E4 is stated from `design.md` (the "check the setup" rule) and from what `implement` does with step code. My call. | It is what the text says. No new behavior. |
| 5 | The checks are structure: the chooser sits at the top of The flow and names both paths, and the runner check no longer says the do-nothing step. | The approach review of 2026-11-12. |

## Existing users

README text only. No plugin file changes.

## First run

A reader sees which path to take before the steps, a branch in the prerequisites, and one line on scenario data.

## Exclusions

- No change to `deliver`, `discover`, `design` or `implement`.
- No gate before application code is edited.
- No per-runner snippets.

## Not proven by this change

- That a newcomer succeeds. The goldfish test is run again. One run is one sample.

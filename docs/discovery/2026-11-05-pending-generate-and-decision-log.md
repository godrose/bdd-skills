# Discovery: `@pending` scenarios and `generate`, and turning on the decision log from `init --detect`

Input: `evidence/plugin-findings.md` in bdd-medium-demo, findings 1 and 2.

## Story

Two problems in `/bdd:init --detect` and the config template, treated as one story: a spec-only branch should stay green, and a user who wants the decision log should be able to turn it on without editing the file by hand.

1. In `specify-only` mode, `design` writes `.feature` files tagged `@pending` with no step definitions. Playwright-BDD's `npx bddgen` fails on them with "Missing step definitions", so the `generate` row cannot pass.
2. The template ships `decision_log` as `off`. `init --detect` never changes a row that already has a value, so turning the log on is a hand edit.

## Existing behavior (from the repo and the demo project)

- README and `run.md` say `run` and the verifier skip `@pending` and undefined steps under it. Nothing covers the `generate` row.
- `implement` removes `@pending` only after the verifier passes. A scenario is still `@pending` while it is being implemented.
- In the demo's Playwright-BDD 9.2.1: `bddgen --tags <expression>` filters generation, and the config option `missingSteps` takes `fail-on-gen` (the default), `fail-on-run` or `skip-scenario`. Verified in `node_modules`.
- Other frameworks were not verified. In bdd-netcore, `generate` is a plain `dotnet build`.
- `init.md` says never overwrite the config and never change a row that already has a value.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | One story or two? | One. | Both are about `init --detect` and the template. |
| 2 | How to stop `bddgen` failing on `@pending`? | Tell the user to set `missingSteps: 'fail-on-run'` in `playwright.config.ts`. The plugin does not edit it. | It is the framework's own switch. It keeps `implement` working, and `run` skips `@pending` anyway. |
| 3 | Filter in the `generate` row (`--tags "not @pending"`)? | No. | It would drop the scenario being implemented, because `@pending` is removed only after the verifier passes. |
| 4 | Other frameworks | The plugin text stays framework-neutral: if your `generate` fails on scenarios with no steps yet, find the setting that defers it to run time. Only `playwright-bdd` gets the named setting. | Only Playwright-BDD was verified. |
| 5 | Where is the hint shown? | `init --detect` when it detects `playwright-bdd`, and `design` at handoff in `specify-only` mode. | The user hits it at those two points. |
| 6 | How can `init --detect` turn the log on? | When `decision_log` is `off` and `decisions_dir` has no decision files, ask "Turn the decision log on?" and write `on` only on approval. | It works for new and existing configs. Nothing is written without approval. |
| 7 | Scope of the exception to "never change a filled row" | Only `decision_log`, only the shipped default, only with approval. | The other default rows have per-run flags or are tuning knobs. This row turns on a whole feature. |
| 8 | The template default | Stays `off`. | Opt-in stays the default. |

## Existing users

- A config with `decision_log: on` is untouched.
- A config with `off` gets the question on each `--detect` run, until they approve or the decision files exist. Declining is not remembered.
- A Playwright-BDD project that already sets `missingSteps` is not told again. The hint appears only when the setting is absent. `init` reads the config file, it does not run the project.
- A project that does not use Playwright-BDD sees no new text.

## First run

A fresh project has the template with `decision_log: off`. `init --detect` proposes rows as before, then asks about the decision log.

## Candidate exclusions (all confirmed)

1. No edits to project code, such as `playwright.config.ts`. Reason: it is the user's code.
2. No `generate` advice for frameworks other than Playwright-BDD. Reason: not verified.
3. No `--tags "not @pending"` in the `generate` row. Reason: it hides the scenario being implemented.
4. No exception for other rows. Reason: only `decision_log` turns on a feature.
5. No write without approval, and no change to other filled values. Reason: the rule stays.
6. No "don't ask again" memory. Reason: no new stored setting. Teams that keep it off see the question again.
7. The template keeps `off`. Reason: opt-in stays the default.

## Readiness

Ready for `bdd:design`. No open questions. Every exclusion is confirmed.

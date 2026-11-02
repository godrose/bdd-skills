# Discovery: make implement usable for projects without a UI

## Story

A trial on a server-side .NET suite with no UI ran through `commands/implement.md`. The text mixes a generic loop with browser and TypeScript advice, so the model had to decide which rules applied. Wording that only fits a UI or one language: "explore UI, discover selectors", reading Page Object Models, `--headed`, the selector rules block, import discipline under `--noUnusedLocals`, `error-context.md`, `video.webm`, `trace.zip`, `$testInfo.attach()`, `.js` extensions for node16.

## Existing behavior (from the plugin)

- Only the failure-evidence list and the selector block say "UI" at all. Nothing says when the UI advice applies.
- `/bdd:init --detect` already inspects the build files, the test framework config, CI files and the README, and writes the result into `bdd-config.md`. The optional rows `error_context` and `show-trace` are filled only when the framework provides them.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How is the UI and language advice handled? | Keep it, gate it, and add a neutral core. No config change. | Existing Playwright and TypeScript users keep their hints. A new row would be one more setting for every project. |
| 2 | How does `implement` know whether the UI rules apply? | It reads the config. UI rules apply when `error_context` or `show-trace` is set. `implement` does no detection of its own. | `init --detect` already owns detection and writes the result into the config. A second detector would duplicate it. This replaces an earlier draft that inferred the kind from `tsconfig`, page snapshots and page objects. |
| 3 | Is import discipline gated by language? | No. It becomes a general rule, with TypeScript (`--noUnusedLocals`) and .NET (`-warnaserror`) as examples. | Strict unused checks exist in many languages. |
| 4 | The `.js` extension rule | Reworded by its trigger: "where the module system requires explicit file extensions (Node ESM, TypeScript with node16 or nodenext resolution)". | Plain JavaScript ESM needs extensions too. The rule is not about TypeScript. |

Alternatives rejected: move the advice into the project's `domain-knowledge` skill (existing UI users would lose hints), a `project_kind` config row (one more row for every project), and a kind-detection block in `implement`.

## Edge cases (all confirmed, as revised)

1. Mixed project: the UI rules apply when the evidence is UI evidence, because the gate is the config rows.
2. Neither `error_context` nor `show-trace` is set (the project has no UI, or never ran `--detect`): use the neutral core and say so in one line. The person can correct it.
3. Phase 0 page-object reading applies only if the project uses page objects. Otherwise read the helpers or clients the steps use.
4. `--headed` becomes "the project's visual-debug flag, if the test command has one, for UI projects". Never add a flag the config does not show.
5. The Phase 3 artifact list becomes "inspect the artifacts in **test_results_dir**", with `error-context.md`, `video.webm` and `trace.zip` kept as UI examples.
6. The conventions table is labeled as the Playwright and TypeScript example. Other stacks use their equivalents from `state_fixture` or `domain-knowledge`. Nothing is deleted.
7. The explicit-extension rule carries its own trigger (decision 4). The other quality rules stay generic.
8. The description, intro and retry rule become neutral: "the system under test", "the evidence".
9. Existing UI and TypeScript users see no change in behavior.

## Candidate exclusions (all confirmed)

1. No new config row.
2. No removal of any UI or language advice.
3. No change to `run.md`, `verifier.md` or the template.
4. No playbooks for other stacks such as .NET or Java. The neutral core is generic.
5. No project-kind detection in `implement`. `init --detect` owns detection.

## Spec points

- **Existing users:** their configs and project files are untouched. The gated advice still applies to projects that set `error_context` or `show-trace`.
- **First run:** a fresh project with neither row set gets the neutral core, and the one-line note says so.
- **Exclusions:** see above. A UI project that has set neither row will not get the UI rules until the rows are filled, for example by `/bdd:init --detect`.
- **Files that change:** `commands/implement.md` and the tests. No version bump, since the plugin tracks commits.

## Readiness

Ready. No open questions.

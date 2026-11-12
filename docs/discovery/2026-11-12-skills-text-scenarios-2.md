# Discovery: the skills text checks as scenarios (PR 2 of 3)

> Superseded in part by `2026-11-12-approach-review.md`. Many of the phrase checks written here were dropped or trimmed afterwards. Kept as the record of the migration.

Input: `tests/test_skills.sh`, `tests/features/`, `tests/steps/`, and a dialogue with the builder. Part 2 of 3 of `docs/discovery/2026-11-11-skills-text-scenarios.md`. Part of `docs/discovery/2026-11-11-scenario-suite.md`.

## Story

Move the checks in `tests/test_skills.sh` on the design command (`plugin/commands/design.md`) and the implement command (`plugin/commands/implement.md`) to scenarios. About 153 checks. Part 1 holds the structure, template, discover, run and verifier checks.

## Kind of check

These are checks of what text says. Nothing runs. Each scenario reads a Markdown file and looks for a phrase, a missing phrase or an order. The migration adds no checks.

## Overlaps with existing scenarios (not written again)

- Plugin note to run `/bdd:init` on design and implement: `plugin-text-rules`.
- `${CLAUDE_PLUGIN_ROOT}/scripts/decisions.sh` and the "script is not part of the plugin" note in design: `plugin-text-rules`. The old checks look for `decisions.sh fingerprint` and `decisions.sh check`, which are different, so they are written.
- Red-first text in implement: `implement-red-first` and `implement-red-first-scope`. The old file has no assertion on it.
- Em-dash checks: `plugin-text-rules`.
- Same phrases in `deliver.md`: `deliver-gates`, `deliver-stops`. Another file, so the design and implement phrases are written.
- Template rows, README and `docs/known-gaps.md`: part 1, part 3 or `known-gaps`.

## Existing users and first run

- Existing users: no file under `plugin/` changes. A project that installed the plugin sees nothing.
- First run: `bash tests/run.sh` needs the runner from `npm ci`. Without it the run says so and stops.

## Agreed examples (PR 2)

Design:

- **E1** `skills-design-modes`: the modes, the absent `workflow_mode`, the stops at the approved spec, and the deliver hooks.
- **E2** `skills-design-summary`: the five headings, and the summary file and undefined-steps text.
- **E3** `skills-design-generate-row`: no tag filter on the generate row, and the reversal.
- **E4** `skills-design-config-rows`: the config rows it reads, the manual-only folder, no `@manual` default, a missing config stops, and `comma-separated`.
- **E5** `skills-design-assertion-check`: Pass C, after Pass B.
- **E6** `skills-design-title-check`: Pass D, after Pass C.
- **E7** `skills-design-assumptions`: assumptions are listed and not chosen silently.
- **E8** `skills-design-lint`: the draft is linted before it is shown.
- **E9** `skills-design-outline`: Outline against separate scenarios is offered by name.

Implement:

- **E10** `skills-implement-spec-status`: approved spec, step status, tag handling, no `@manual` default.
- **E11** `skills-implement-tags`: the selection line and the tag defaults.
- **E12** `skills-implement-prepare`: the prepare row, before generate and test.
- **E13** `skills-implement-zero-tests`: no tests ran is not a pass.
- **E14** `skills-implement-assertion`: a reused assertion that does not fit stops, and approved data is not edited.
- **E15** `skills-implement-framework-neutral`: UI advice is gated by the config.
- **E16** `skills-implement-step-batch`: steps are grouped by risk and the plan is in the final report.
- **E17** `skills-implement-locators`: an ambiguous locator is scoped, not settled with `.first()`.
- **E18** `skills-implement-open-decision`: the stop shows `Open decision:`, `Found:` and `Options:`.
- **E19** `skills-implement-config`: a missing config stops, and `comma-separated`.

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | `specify-only` is not checked alone. `--specify-only` implies it. | A substring of a checked phrase adds no check. Same as part 1, decision 7. |
| 2 | `size gate` and `unautomated_tag` in design are each checked once. | The old file checked each once in the groups that remain. A duplicate adds no check. |
| 3 | No new steps. | `the plugin command`, `the file`, `it contains:`, `it does not contain`, `it mentions these in this order:` fit. |
| 4 | `tests/test_skills.sh` stays whole until part 3. The migrated checks run twice. | Same as part 1, decision 2. |
| 5 | Outlines over the file use one column, written compactly. | The old loops ran the same phrases over several files. |
| 6 | The builder's mutation check is the red proof. No mutation is run in this change. | The builder asked for it. |

## Exclusions

- Deleting `tests/test_skills.sh` in this pull request.
- Checks the old file did not make.
- The triage, reconcile, init, README and docs groups: PR 3.
- Any change to a file under `plugin/`.

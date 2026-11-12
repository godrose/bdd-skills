# Discovery: which text checks stay after the migration

Input: the scenario suite after the last bash file moved (120 feature files, 676 scenarios), a review comment on PR 68 ("this looks like an implementation detail testing, instead of the outcome"), and a dialogue with the builder. Follows `2026-11-11-scenario-suite.md`.

## Story

The migration kept every old check and added none. That moved about 75 files of phrase checks on prompt and doc text into scenarios. A review asked whether those checks test the outcome. Decide which stay.

## Kind of check

A phrase check says that a word is in a file. It catches an accidental deletion. It does not catch a changed meaning, and it fails on a harmless reword. The behavior of a prompt is guarded by the eval cases and the flow harness, which cost money and do not run on every push.

## Rule

Keep a text check only if one of these holds:

1. It is a contract between files: plugin names, the script path, the config keys the commands read, the plugin note, the manifests, the missing-config stop.
2. It marks a reversed decision: a `does not contain` for text that was removed on purpose.
3. It is policy: the directory policy, no em-dash, no project-install names, frontmatter, no local path in a public note.

## Result

- Kept: 23 files, unchanged (74 scenarios).
- Trimmed to the reversal scenarios: 14 files. `skills-design-assumptions`, `skills-design-config-rows`, `skills-design-generate-row`, `skills-discover-rules`, `skills-implement-framework-neutral`, `skills-implement-locators`, `skills-implement-spec-status`, `skills-implement-step-batch`, `skills-implement-tags`, `skills-run-prepare`, `skills-run-tags`, `skills-verifier-selection`, `init-leftovers`, `deliver-trial-record`.
- Trimmed to the existence check and the missing-config stop: `deliver-shape`.
- Dropped: 35 files (about 90 scenarios). `skills-design-assertion-check`, `skills-design-lint`, `skills-design-modes`, `skills-design-outline`, `skills-design-summary`, `skills-design-title-check`, `skills-discover-hooks`, `skills-discover-look-first`, `skills-discover-plain-words`, `skills-discover-sections`, `skills-implement-assertion`, `skills-implement-open-decision`, `skills-implement-prepare`, `skills-implement-zero-tests`, `skills-init-text`, `skills-readme-detect`, `skills-readme-init`, `skills-readme-phrases`, `skills-reconcile-commands`, `skills-run-generate-skip`, `skills-run-zero-tests`, `skills-triage-fragments`, `skills-triage-phrases`, `init-audit`, `init-detect`, `init-hints`, `init-skill-roles`, `deliver-existing-and-permissions`, `deliver-gates`, `deliver-listings`, `deliver-look-at-result`, `deliver-no-developer`, `deliver-records`, `deliver-report`, `deliver-stops`.
- Kept on purpose, as the one rule where the old check was a deliberate guard: `implement-red-first`, `implement-red-first-scope` (known gap G5 names the first).
- After: 85 feature files, 538 scenarios. No step definition became unused.

## Existing users and first run

Nothing under `plugin/` changes. Users see no difference. A contributor runs `npm ci` and `bash tests/run.sh` as before.

## Exclusions

- No change to the kept files.
- No new check. The reconcile flags and codes stay as phrase checks. A cross-check that every flag named in `reconcile.md` is accepted by `decisions.sh` is an idea, not part of this change.
- The eval cases and the flow harness are not changed, and nothing is added to the nightly.
- The cleanup of `tests/lib.sh`, `tests/test_lib.sh` and the bash loop, and the move to `specs/`, is the next change.

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Apply the rule above and drop or trim the rest. | The checks pinned phrases and not outcomes, and made every prompt edit cost a test edit. |
| 2 | Keep the reversal scenarios in trimmed files, and drop the positive ones. | A reversal marks a mistake that was made once. A positive pin marks nothing. |
| 3 | Keep `implement-red-first` and `-scope`. | G5 names them as the only check on the rule, and there is no eval. This replaces the plan to drop them. |
| 4 | Keep `deliver-shape` for the missing-config stop and the existence check. | The plugin-text outline for the config stop does not cover `deliver.md`. |
| 5 | Leave older packs as they were and add a note on the ones this changes. | A pack is a record of its day. |
| 6 | This reverses "a migration adds no checks" only in the sense that checks are removed. No check is added. | The migration rule was about not widening coverage. It did not say every check is worth keeping. |

## Risk

A prompt edit that deletes one of the dropped rules no longer fails the suite. The guard for that is the eval cases and the flow harness, which are open gaps (G7, G12). The next review point is whether a small subset of them should run on a schedule.

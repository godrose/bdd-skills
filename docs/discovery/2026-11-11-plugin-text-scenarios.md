# Discovery: the plugin text checks as scenarios

> Superseded in part by `2026-11-12-approach-review.md`. Many of the phrase checks written here were dropped or trimmed afterwards. Kept as the record of the migration.

Input: `tests/test_plugin.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

The two manifests, the command and agent files, the config template and the plugin text rules have checks in `tests/test_plugin.sh` (169 lines). Migrate them to scenarios. A migration adds no checks.

These are checks of files and text. Nothing runs. Three are about file names or modes (E12, E13) and one scans the repo (E34). The scenarios say so under `Feature:`.

## Overlap with existing scenarios

Not written again.

- `layout-manifests-and-folders.feature`: both manifests exist, the marketplace source is `./plugin`, the config template exists.
- `deliver-shape.feature`: `deliver.md` exists and has the `/bdd:init` plugin note.
- `deliver-existing-and-permissions.feature`: `deliver.md` has no project-install path or skill name. The group step here reads every command, so it reads `deliver.md` again. The old scenarios stay.
- `deliver-records.feature`: "Nothing was recorded" in `deliver.md`.
- `install-fresh-files.feature`: the installer writes the source line. The `install.sh` source-line check (line 79) is skipped for this reason.
- `deliver-shape`, `readme-hero` and `evals-workflow` hold their own em-dash checks.

## Overlap with `test_skills.sh` (not migrated yet)

Written once here. The later migration skips them.

- `discover.md`, `triage.md` and `reconcile.md` exist.
- The `feedback-intake` row of the template (the weaker substring check skips).
- No em-dash in `discover.md`, `reconcile.md` and `triage.md` (the repo-wide scan, E34).

## Agreed examples (all from code)

- **E1-E8** Manifests: name `bdd`, semantic version, marketplace version equal, changelog entry, description, marketplace plugin name and name, author and owner full name.
- **E9-E15** Files: seven commands, the verifier agent and its name, the decision schema, the executable decisions script, no `bdd-` file names, no `.claude/commands` or `.claude/agents`, the `.gitattributes` line.
- **E16-E22** Text rules: no project-install path, no project-install skill name (`bdd-implement-scenario` allowed), the script call, the plugin notes, the template has no em-dash, the missing-script wording.
- **E23-E28** The init command: basics and detect, leftovers, audit, skill roles, hints.
- **E29-E32** The triage rename, the template row, the design and discover text.
- **E33-E34** The README headless note and the repo-wide em-dash scan.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | One file or several? | Ten small files named `plugin-*` and `init-*`, by what a maintainer notices. The init basics go in `init-detect`. | The builder asked for ten. |
| 2 | Overlap with existing scenarios | Not written again. | The scenarios exist. |
| 3 | Overlap with `test_skills.sh` | Written once here. | One home for each check. |
| 4 | The `install.sh` source line | Skipped. | An install scenario already runs the installer and checks the line. |
| 5 | JSON checks | One step reads the subject as JSON by a dotted key. | The same step serves both manifests. |
| 6 | Skill-name check | Seven names by `none of them contains`, `bdd-implement` by a step that allows `bdd-implement-scenario`. | The old check removed that name before it looked. |
| 7 | The em-dash scan | Same exclusions as before: `.git`, `docs`, `results`, `node_modules`, `lib.sh`, `test_lib.sh`. The dash is built from its code. | The old scan; the new files hold none. |
| 8 | The old file | Deleted after the builder's mutation check. | Same as #59 to #64. |

## Existing users

Nothing changes in a user's project. Nothing under `plugin/` changes.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new files run beside the bash file until it is deleted.

## Exclusions

- Any new check, and any change under `plugin/`.
- The `install.sh` source-line check.
- Deleting `tests/test_plugin.sh` before the mutation check.

## Frameworks and platforms

None. The scenarios read JSON and Markdown files of the repo.

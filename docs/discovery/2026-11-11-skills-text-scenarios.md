# Discovery: the skills text checks as scenarios (PR 1 of 3)

Input: `tests/test_skills.sh` (387 lines, about 442 assertions), `tests/features/`, `tests/steps/`, and a dialogue with the builder. Part of `docs/discovery/2026-11-11-scenario-suite.md`.

## Story

`tests/test_skills.sh` is the last big bash file. It pins what the command text, the agent text, the config template and a few listings say. Move its checks to scenarios in many small files grouped by what a maintainer would notice. It is too large for one pull request, so it goes in three.

## Kind of check

These are checks of what text says. Nothing runs. Each scenario reads a Markdown file and looks for a phrase, a missing phrase or an order. The migration adds no checks.

## Split

| PR | Groups | Assertions |
|----|--------|-----------|
| 1 (this one) | structure, template, discover, run and verifier | about 150 |
| 2 | design, implement | about 150 |
| 3 | triage, reconcile, init text, README, docs files, then delete the file | about 120 |

## Overlaps with existing scenarios (not written again)

- `deliver.md` "does not exist, say so and stop", template name and plugin note: `deliver-shape`.
- `git log --diff-filter=D` in discover and deliver, and "Nothing was recorded": `deliver-records`.
- Not an overlap: the default out-of-scope row text in `deliver.md` (`deliver-records` holds only the key). The earlier exclusion for deliver text says it stays here, so it is written in this pull request.
- Plugin note to run `/bdd:init` on design, implement, run, triage and reconcile: `plugin-text-rules`.
- The `feedback-intake` template row, `triage.md` existing, the triage rename: `plugin-renames-and-text`.
- The template em-dash check and the repo-wide em-dash scan: `plugin-text-rules`. They cover the three `assert_no_added_emdash` calls and the per-file em-dash checks, which are dropped.
- Known gaps file and gap list: `known-gaps`. G10 and G12 are not there and stay (PR 3).
- README install order, "Optional config rows" summary, `/bdd:init` "never overwrites": `readme-order`, `readme-folded`, `init-detect`.
- `install-existing-config` matches `reconciler` and `step_batch`, but it checks installer output on a user's config. Different subject, so those are written.

## Existing users and first run

- Existing users: no file under `plugin/` changes. A project that installed the plugin sees nothing.
- First run: `bash tests/run.sh` needs the runner from `npm ci`. Without it the run says so and stops (see the suite pack).

## Agreed examples (PR 1)

- **E1** Every command and agent opens with a frontmatter line and has a `description:` or `name:` line.
- **E2** Every skill role named in the config template has a command or agent file.
- **E3** No command or agent names `bdd:feedback`.
- **E4** The template has the workflow, discovery, tag, decision log, out-of-scope and reconciler rows. `unautomated_tag` is `@pending`, not `@manual`. The `prepare` and `step_batch` rows are empty with an "(optional" note. The generate row says it may be empty. The template has no `required_tags`, `adapters_dir` or `domain_dir` row. It says `comma-separated`.
- **E5** The discover command has its seven headings, its defaults and stops, its size-gate and empty-story phrases, its deliver hooks (and the default out-of-scope row in `deliver.md`), Step 0 (look first) before Step 1, its plain-words rules and Step 1 before Step 3b. It does not stop on a missing config.
- **E6** The run command and the verifier agent share the tag, generate-skip, missing-config, prepare and zero-tests rules. Each has its own order and selection phrases. Neither mentions `deliver`.

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | The checks move in three pull requests along the groups, and this one is first. | The builder approved the split. The file is too big for one review. |
| 2 | PR 1 leaves `tests/test_skills.sh` whole. The migrated checks run twice until PR 3 deletes the file. | The lines are mixed with the checks for PR 2 and 3, and a wrong cut would drop a check. A check that runs twice costs nothing. Reversal: this replaces the first plan, which was to remove the migrated lines in PR 1. |
| 3 | Run and verifier checks are outlines over the file path, one column. | The old loops ran the same phrases over both files. |
| 4 | Three new steps: frontmatter, role files, `it does not contain:` with a table. | No existing step fits. The rest reuse `it contains:`, `it mentions these in this order:` and `the file {string}`. |
| 5 | The `prepare` and `step_batch` rows are checked as the substring `\| prepare \| `` (optional`, without the line-start anchor. | The row starts with a pipe, so a match inside a line needs an earlier pipe cell. The step set has no anchored match. |
| 6 | `stop and ask` in discover is checked once. The old file checked the same literal twice (lines 25 and 311). | A duplicate adds no check. |
| 7 | `unautomated_tag` and `automated_tag` are checked with the `@pending` row and the `automated_tag` row, not twice. | The stronger row check implies the key. |
| 8 | E3 covers every command and agent, as the old loop did. | The old check read all of them. |

## Exclusions

- Deleting `tests/test_skills.sh` in this pull request.
- Checks that the old file did not make.
- The design, implement, triage, reconcile, init and README groups: PR 2 and PR 3.
- Any change to a file under `plugin/`.
- A mutation check is recorded in the pull request, as in the earlier migrations.

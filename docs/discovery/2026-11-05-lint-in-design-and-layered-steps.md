# Discovery: lint on the draft in `design`, several step folders, and `generate` for IDE-generated frameworks

Input: a read-only review of four existing BDD suites in other stacks, and a trial of `/bdd:init --detect` on copies of two of them. No project names are recorded here on purpose.

The four suites:

- Two suites that enforce house rules with a gherkin linter and custom rules, and require a ticket tag on every scenario.
- Two layered solutions. Step code is split into an intent layer and an adapter layer, and the framework generates code in the IDE, with the generated files committed.

## Story

Three changes, one pack. A and B come from the review. C is a small fix found in the trial.

- **A. Lint on the draft.** An engineer on a project with strict house rules runs `/bdd:design`. The scenarios should pass the project's lint the first time, not be rejected by CI after approval.
- **B. Several step folders.** On a layered project, step code lives in more than one folder. `implement` and `design` should search all of them when they look for steps to reuse.
- **C. `generate` for IDE-generated frameworks.** In the trial, `init --detect` proposed `_(not needed: ...)_` for `generate` on a framework that generates its code in the IDE. That is wrong. The template says "empty if the framework reads .feature files directly", and this framework does not.

## Existing behavior (from the repo and the trial)

- `design` already runs the **lint** row, but only after approval, only when `decision_log` is `on`, and on files already written. `triage` runs it on its edits. `discover` runs it on any draft text that exists.
- `design` never lints the draft before showing it. A project with strict rules finds out in CI.
- The **lint** row is one command. It usually scans the whole features folder, so its output also holds findings in files that were already there.
- **steps_dir** is read only in command text (`design`, `implement`, `discover`, `init`). No script and not `install.sh` reads it. The `init` audit checks the whole cell as one path.
- In the trial on a layered solution, `init --detect` named one step folder and mentioned the other in a note. In the trial on a one-project solution it proposed `_(not needed)_` for `generate` at low confidence. On the layered solution it said `unknown`, which is right.
- `design-vague-ac` (an eval) requires that no `.feature` file is written before approval.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | One pack or three? | One pack for A, B and C. | They share the trial evidence. C is a one-sentence fix and the pack records it as trivial. |
| 2 | How does `design` learn the project's lint rules? | It runs the **lint** row on the draft and fixes the findings. It does not read or interpret rule files. | It works with any linter, including custom rules, and needs no parsing. |
| 3 | What if the lint run fails for a reason other than findings (for example, missing tooling)? | Warn and continue. Show one line: "lint did not run: <error>. The scenarios are unchecked." | A tooling problem must not block design. The user sees the risk. |
| 4 | Which findings does `design` act on? | Only findings in the draft file. It lists the rest in one line ("N findings in existing files, not touched"). | `design` must not change files the user did not ask about, and the PR stays small. |
| 5 | A `required_tags` row for a mandatory tag such as a ticket id? | No new row. When a finding needs a value `design` cannot know, it asks the user, then adds the tag. | Lint already catches the missing tag. A row would duplicate what the linter enforces. |
| 6 | How does the config name more than one step layer? | **steps_dir** takes several paths. No `adapters_dir` or `domain_dir` rows. | No new rows, and single-path configs keep working. The plugin does not impose a layering. |
| 7 | Separator | A comma, with an optional space. | It reads naturally in a table cell, and the README already lists values with commas. A path that contains a comma is rare. |
| 8 | Where does the draft live while it is linted? | A temp file inside **features_dir**, named with the prefix `.bdd-draft-`, deleted right after the lint run and before the draft is shown. | The linter then sees the draft with the project's own path and name rules. The command in the row stays as the user wrote it. |
| 9 | What happens to the `design-vague-ac` eval? | Amended in design: the check (`features/experiments-delete*.feature` exists) does not match the `.bdd-draft-*` name, and the fixture has no lint row, so the check stays. Only the case description gets a clause: a temp draft file may exist during the run and is gone before approval. | The temp file is gone before the draft is shown. The first wording of this decision assumed the check would match it. |
| 10 | `generate` for frameworks that generate code in an IDE | `init --detect` proposes `unknown` with a note, never `_(not needed)_`. `_(not needed)_` stays for frameworks that read `.feature` files directly. | A wrong "not needed" makes `implement` skip generation and leave stale generated files. |

## Existing users

- **No lint row:** no change. `design` skips the lint step, as `discover` does.
- **A lint row, log off:** `design` now lints the draft before showing it. Before, it did not lint at all in this case. The command is the one the user configured, so a lint command with a fix flag will fix files as it does today. This is the user's choice, and it is stated in the README note.
- **A lint row, log on:** the lint run after approval stays. The earlier run is added.
- **A single-path `steps_dir`:** unchanged.
- **A user's own file named `.bdd-draft-*`:** the plugin deletes only the file it created in this run, not a pattern.
- **A config written for the new list form, read by an older plugin version:** the old audit reports the list as one path that does not exist. The user updates the plugin. This is the usual pre-release case.

## First run

A fresh project has the template with an empty **lint** row and a placeholder **steps_dir**. `design` skips the lint step. `init --detect` proposes **steps_dir** as one or several paths from the files it finds, with the evidence for each. For `generate` on an IDE-generated framework it says `unknown` and names the files searched.

## Edge and negative cases

The first two follow from decisions 3 to 5. The rest were confirmed by the builder.

- Lint finds nothing on the draft: show the draft with "lint: no findings".
- Lint finds problems in the draft that need a value `design` cannot know: ask the user, add the value, run lint again.
- The same finding comes back after a fix: stop after two rounds and show the draft with the finding listed. Do not loop.
- The lint run is interrupted: a `.bdd-draft-*` file may remain in **features_dir**. The next `design` run reports it before it starts.
- The temp file name makes the linter complain about the file name itself: the finding is ignored and reported as such.
- `steps_dir` lists a path that does not exist: the `init` audit reports that entry, as it does for a single path today. The other entries are used.

## Candidate exclusions

Exclusions 1 to 5 follow from decisions 2 to 8. Exclusions 6 to 8 were confirmed by the builder.

1. `design` does not read or interpret lint rule files. Reason: running the linter is simpler and works for every linter.
2. `design` does not edit files that were already there to fix lint findings. Reason: they are not part of the change.
3. No `required_tags` row. Reason: the linter enforces tags already.
4. No `adapters_dir` or `domain_dir` rows, and no layer-aware advice. Reason: the plugin does not impose a layering.
5. `design` does not install lint tooling. Reason: it runs only the command the user configured.
6. `init --detect` does not run the project's builds or tests to find `generate`. Reason: the rule stays.
7. No change to the plugin's behavior on frameworks that read `.feature` files directly. Reason: they already work.
8. The plugin does not scan for secrets in scenarios. Reason: a project linter rule can do it, and the lint step now runs it.

## Tests to write first

Each must fail before the change.

- `design.md` says the draft is linted before it is shown, and names the temp file prefix.
- `design.md` says a failed lint run warns and continues.
- `design.md` says only findings in the draft are acted on.
- `design.md`, `implement.md`, `discover.md` and `init.md` say `steps_dir` can list several paths, comma-separated.
- `init.md` says the audit checks each entry of a list.
- `init.md` says IDE-generated frameworks get `unknown` for `generate`, not `_(not needed)_`.
- The `design-vague-ac` case description gets a clause about the temp draft file, and `tests/test_evals.sh` still passes.

## Readiness

Ready for `bdd:design`. No open questions. Every exclusion is confirmed.

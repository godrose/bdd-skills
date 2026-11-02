# Discovery: a `prepare` row for things the tests need built first

## Story

Some projects need artifacts built before the tests can run, beyond what the `generate` and `test` commands do. A trial on a .NET project showed it: the specs launch server executables that must be built first, with eight solutions to build. On a fresh checkout `/bdd:run` and the verifier ran generate and test. Every scenario then failed with `Process N is not running`, which hides the real cause. The run reported the same failure many times and gave no hint that a build was missing.

## Existing behavior (from the plugin)

- `commands/run.md` step 5.1 says to "run the install command if missing", but no config row names an install command.
- Step 5.4 covers what a feature's Background needs (for example a server start). It does not cover build outputs the test harness launches.
- `agents/verifier.md` goes from generate straight to test. It has no prerequisite step.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Who makes sure the artifacts exist? | The project names a command in a new optional `prepare` row. `run` and the verifier run it. | Only the project knows what it needs. Same model as `generate`. |
| 2 | When does it run? | On every run. The project keeps the command cheap, for example a script that skips unchanged builds. | The plugin keeps no state, so it cannot get stale. A marker row would add a second row and never refresh a stale build. |
| 3 | In what order? | `prepare`, then `generate`, then `test`. | Prepare is the project's setup, so it comes first. A project that needs the opposite can call generate from inside its prepare script. |

## Candidate exclusions (all confirmed)

1. No auto-detection of a prepare command from project files. The project names it.
2. No marker row and no staleness check (decision 2).
3. No shared-failure safety net. With no `prepare` row the run behaves as today.
4. No starting of long-running services. Prepare builds or fetches. Servers a scenario needs stay a Background or hook matter.
5. `/bdd:init --detect` does not fill the row. It stays empty until the project sets it.

## Defaults (confirmed)

- Row absent, empty, in `<...>` form, or a note such as `_(not needed)_`: skip the step and say so, as for `generate`.
- If `prepare` fails: report the error and stop. The tests are not run.
- The verifier does the same and only reports. It never edits.

## Spec points

- **Existing users:** configs without the row keep working unchanged. The row is absent, so the step is skipped. A project's own `bdd-*` skills and files are untouched.
- **First run:** a fresh config from the template gets the row in placeholder form. A placeholder counts as empty, so the step is skipped until the project sets it.
- **Exclusions:** see above. The change does not fit projects whose tests need only generated files, and they leave the row empty.
- **Files that change:** `bdd-config.template.md`, `commands/run.md`, `agents/verifier.md`, the tests that check the template rows and the command text, and a plugin version bump.

## Readiness

Ready for `bdd:design`. No open questions.

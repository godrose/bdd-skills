# Discovery: `init --detect` audits existing values, and the leftover check covers old installs

Input: `docs/discovery/2026-11-04-dogfood-dotnet-project.md`, findings 1 and 2.

## Story

When `/bdd:init --detect` runs on a brownfield project, it should report existing config values that do not match the disk, and recognise leftovers from old installs. Today it does neither. In the .NET project it stopped at "no placeholder" and never looked at four wrong values. It also missed the old installer files and called two of them "your own skills".

## Existing behavior (from the plugin)

- `commands/init.md` Detect step 1 stops when no row is a placeholder. The path check in step 4 is therefore unreachable for rows that already have a value.
- `commands/init.md` Leftovers finds files by the `# Source:` line, plus the current command names `bdd-<name>` for discover, design, implement, run, triage and reconcile, and `bdd-verifier`. It says any other `bdd-*` file "is your own skill".
- `install.sh` (legacy block) already deletes three old files on re-install: `bdd-scenario-design.md`, `bdd-implement-scenario.md` and `test-feature.md`. The dogfood doc named the first two. `test-feature.md` is a third name the leftover check also does not know.
- The installer's own comment says to remove that block six months after the 2026-06-22 rename. The old names are not yet safe to forget.
- `install.sh` writes `# Source:` only through `install_skill`. Nothing in this repo writes a `.gitignore` header, so the "installed from" comment seen in the .NET project came from an older installer. Its form is not stable.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Does `--detect` audit when no row is a placeholder? | Always. The audit is read-only. With nothing wrong it prints one line. | The .NET project's config was wrong because nobody asked. The cost is one line. |
| 2 | Which checks are in the audit? | A: path values that do not exist on disk. B: Skill Roles names that resolve to neither a plugin skill nor a file in `.claude/commands` or `.claude/skills`. | Both are exact and cannot raise a false alarm. |
| 3 | Header text and `test` row filters? | Not checked. The report ends with a "not checked" line that names them. | They are guesses. A wrong guess makes users distrust the report. |
| 4 | Old install names | `bdd-scenario-design`, `bdd-implement-scenario` and `test-feature` count as leftovers by name alone. | The installer deletes these itself, so a project's own file by these names is not a case to protect. |
| 5 | A `bdd-*` file that matches no rule | Reported as "origin unknown, left alone". The text no longer says "your own skill". | The check cannot prove ownership. The dogfood run showed the wrong claim misleads. This replaces the current "your own" wording. |
| 6 | The `.gitignore` header | Evidence only. If present, the report mentions it next to the unknown files as a hint. It never classifies a file. | Its form depends on the installer version. |

## Candidate exclusions (all confirmed)

1. The audit never edits a value. It reports only.
2. No check of header text or test filters (decision 3).
3. The audit does not run the project's commands. It reads files only.
4. No deletion or renaming of leftovers.
5. Repos with several test projects (finding 4) are out. The audit checks the one config it finds.
6. `reconcile` with no decision log (finding 3) and the new review patterns (finding 4) get their own discovery.
7. Plain `/bdd:init` without `--detect` still only copies the template. Its leftover report does get the new rules.

## Spec points

- **Existing users:** a config whose values all resolve sees one extra line. Their own files are never touched. A file of unknown origin is left alone and reported as such.
- **First run:** a fresh template holds only placeholders and relative defaults. The audit skips placeholders, so it reports nothing on a fresh project.
- **Exclusions:** see above. The audit does not fit a check on commands, and it does not cover frameworks with no config file.
- **Files that change:** `commands/init.md`, the README sentence that says the `# Source:` line tells your own `bdd-*` skills from the installer's, and the tests that check the init text (`tests/test_plugin.sh`). New tests must fail before the change.

## Readiness

Ready for `bdd:design`. No open questions.

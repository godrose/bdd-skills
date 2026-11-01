---
description: "Create .claude/bdd-config.md from the plugin's template. With --detect, also propose values for the placeholder rows from the project's own files and write only what you approve."
allowed-tools: ["Bash", "Read", "Grep", "Glob", "Edit", "AskUserQuestion"]
---

## BDD Init

Create `.claude/bdd-config.md` in the current project from the template that ships with the plugin.

Without `--detect`, this command only copies the file. It never overwrites an existing config, and it does not fill in anything. With `--detect`, it also proposes values for the rows that are still placeholders, and writes only the ones the user approves.

### Input

- No argument: copy the template, then stop.
- `--detect`: copy the template if the config is missing, then detect and propose values.

Both forms end by reporting leftover project-file copies (see Leftovers).

### Copy

1. **Check.** Run `test -e .claude/bdd-config.md`. If the file exists, say so and leave it as it is. Without `--detect`, stop here. With `--detect`, go on to Detect.

2. **Copy.** If the file is missing, run:

   ```
   mkdir -p .claude && cp "${CLAUDE_PLUGIN_ROOT}"/bdd-config.template.md .claude/bdd-config.md
   ```

   If the path in this command still starts with `$`, or the template is not found, say the plugin root was not set, and stop.

3. **Say what is next.** Without `--detect`, tell the user the file is a template and still has placeholders in `<...>` form. They must open it and fill in:

   - the **Tooling** table: the `generate`, `test` and `typecheck` commands
   - the **Conventions** table: at least `features_dir` and `steps_dir`

   A value still in `<...>` form counts as empty. The README's Configure section has ready-made row sets for common frameworks. The file should be committed once it is filled in. Mention that `/bdd:init --detect` can propose the values.

### Detect

1. **Find the placeholder rows.** In the Tooling and Conventions tables, collect the rows whose value is still in `<...>` form. Never change a row that already has a value, whatever it is: a command, a path, a default, or a note in `_(...)_` form. If no row is a placeholder, say so and stop.

2. **Inspect the project, read-only.** Look at the build and package files (for example `package.json` scripts, `*.sln`, `*.csproj`, `pom.xml`, `go.mod`), the test framework config, the CI workflow files (for example `.github/workflows/`), the README and `CLAUDE.md`, and the `.feature` files and step definitions. CI workflow files are often the best source for the commands. Do not run the project's commands, builds or tests.

3. **Pick the project.** If the repo holds several test projects (several solutions, or several folders with `.feature` files), ask which one to configure before proposing anything. If there are no `.feature` files and no BDD framework, say so, propose nothing, and stop.

4. **Propose a value for each placeholder row.** For every row give the value, the evidence (the file it came from) and a confidence of high, medium or low.

   - Use the commands the project already uses (package scripts, CI steps, scripts in the repo) before any command of your own.
   - For tag rows (for example `automated_tag`), count how often each tag is used in the `.feature` files, and propose the tag that fits the row, with its count as evidence. Do not report a tag row as unknown without searching the `.feature` files.
   - Write the full path from the project root. Use a full path, never an abbreviation of a project or folder name.
   - Check each path value against the disk. If a value in the config or the files points at a path that does not exist, say so.
   - If the files do not answer the question, write `unknown`. Do not guess. When you write `unknown`, name the files you searched. A default that is not found in a project file is your own suggestion: label it as yours and give it low confidence. For a path pattern, propose a literal glob such as `test-results/**/error-context.md`, never a value in `<...>` form (the config reads that as empty).
   - If a row does not apply (for example `generate` for a framework that reads `.feature` files directly), propose `_(not needed: <reason>)_`.
   - If a command is for another platform than this machine (for example a `.bat` script on macOS), say so in a note.
   - Note anything that stops a command from working locally (a private dependency, a service that must be running).

5. **Ask what to write.** Show the table and the notes. Then ask which rows to write: the high and medium rows, all proposed rows, or a list the user picks. This command writes nothing until the user answers. Rows marked `unknown` are never written. For each important row that is `unknown` (`test`, `features_dir`, `steps_dir`), ask the user for a value, or leave the placeholder.

6. **Write.** Put the approved values into `.claude/bdd-config.md`. Change the value cell only. Show the rows that were written and the rows that are still placeholders.

Running `--detect` again later only touches rows that are still placeholders.

### Leftovers

Projects that used the project-file install may hold copies of the skills next to the plugin, which gives duplicate commands. Report them. Do not delete anything.

1. **Find them.** Run:

   ```
   grep -l "^# Source: https://github.com/godrose/bdd" .claude/commands/bdd-*.md .claude/agents/bdd-*.md 2>/dev/null
   find .claude -maxdepth 2 \( -name decisions.sh -o -name decision.schema.json \) 2>/dev/null
   ```

   The installer writes the `# Source:` line into every skill file it creates. Also count a file as a leftover when it is named `.claude/commands/bdd-<name>.md` with name one of discover, design, implement, run, triage or reconcile, or `.claude/agents/bdd-<name>.md` with name verifier, even without the line (older installs). A file counts only if it exists on disk. A file that git shows as deleted is not a leftover, because it causes no duplicate command.

2. **Report.** If there are none, say nothing about it. Otherwise list each leftover and say the plugin provides the same commands under `bdd:`, so the old files can be deleted by hand. Any other `bdd-*` file in `.claude/commands/` is your own skill: say it stays. Remind the user that the Skill Roles table in `.claude/bdd-config.md` should name `bdd:design` and the other plugin skills.

### Rules

- Never overwrite `.claude/bdd-config.md`, and never change a row that already has a value.
- Without `--detect`, do not fill in any value.
- Writes nothing until the user approves it.
- Do not run the project's commands, builds or tests. Read files only.
- Do not delete or edit the leftover files. Only report them.
- Do not commit.

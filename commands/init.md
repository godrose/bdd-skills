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

1. **Find the placeholder rows.** In the Tooling and Conventions tables, or the two placeholder roles in the Skill Roles table, collect the rows whose value is still in `<...>` form. Never change a row that already has a value, whatever it is: a command, a path, a default, or a note in `_(...)_` form. The one exception is `decision_log`: see Hints. Always run the audit (see Audit below) first, whether or not any row is a placeholder. If no row is a placeholder, report the audit result, say there is nothing to propose, and stop.

2. **Inspect the project, read-only.** Look at the build and package files (for example `package.json` scripts, `*.sln`, `*.csproj`, `pom.xml`, `go.mod`), the test framework config, the CI workflow files (for example `.github/workflows/`), the README and `CLAUDE.md`, and the `.feature` files and step definitions. CI workflow files are often the best source for the commands. Do not run the project's commands, builds or tests.

3. **Pick the project.** If the repo holds several test projects (several solutions, or several folders with `.feature` files), ask which one to configure before proposing anything. If there are no `.feature` files and no BDD framework, say so, propose nothing, and stop.

4. **Propose a value for each placeholder row.** For every row give the value, the evidence (the file it came from) and a confidence of high, medium or low.

   - Use the commands the project already uses (package scripts, CI steps, scripts in the repo) before any command of your own.
   - For tag rows (for example `automated_tag`), count how often each tag is used in the `.feature` files, and propose the tag that fits the row, with its count as evidence. Do not report a tag row as unknown without searching the `.feature` files.
   - Write the full path from the project root. Use a full path, never an abbreviation of a project or folder name.
   - Check each path value against the disk. If a value in the config or the files points at a path that does not exist, say so.
   - If the files do not answer the question, write `unknown`. Do not guess. When you write `unknown`, name the files you searched. A default that is not found in a project file is your own suggestion: label it as yours and give it low confidence. For a path pattern, propose a literal glob such as `test-results/**/error-context.md`, never a value in `<...>` form (the config reads that as empty).
   - If a row does not apply (for example `generate` for a framework that reads `.feature` files directly), propose `_(not needed: <reason>)_`. Use `_(not needed)_` only for a framework that reads .feature files directly. If the framework generates code in the IDE (for example SpecFlow with committed `.feature.cs` files) and no command is in the project files, propose `unknown` for `generate`, name the files searched, and add a note that the generated files may go stale.
   - Step code can sit in more than one folder (for example an intent layer and an adapter layer). Propose **steps_dir** as one path, or several comma-separated, each with its evidence.
   - If a command is for another platform than this machine (for example a `.bat` script on macOS), say so in a note.
   - Note anything that stops a command from working locally (a private dependency, a service that must be running).

5. **Ask what to write.** Show the table and the notes. Then ask which rows to write: the high and medium rows, all proposed rows, or a list the user picks. This command writes nothing until the user answers. Rows marked `unknown` are never written. For each important row that is `unknown` (`test`, `features_dir`, `steps_dir`), ask the user for a value, or leave the placeholder.

6. **Write.** Put the approved values into `.claude/bdd-config.md`. Change the value cell only. Show the rows that were written and the rows that are still placeholders.

Running `--detect` again later only touches rows that are still placeholders. The Hints can still apply, and the audit and the leftover check run every time.

### Audit

The audit looks at rows that already have a value and reports the ones that are wrong. It reads files only. Never edit a value in the audit: the user fixes the config by hand.

1. **Paths.** For every row whose value is a path (for example `features_dir`, `steps_dir`, `config_file`), check it against the disk. A value may list several paths, comma-separated: check each entry. Report each path that does not exist, with the row name and the value.
2. **Skill roles.** For every role in the Skill Roles table that has a value, check that it resolves. A `bdd:<name>` value resolves when the plugin has that skill. Any other value resolves when a file by that name exists in `.claude/commands/` or `.claude/skills/`. Report each value that does not resolve. When it looks like an old name from the project-file install (see Leftovers), say which plugin skill replaced it.
3. **Skip.** Skip placeholders in `<...>` form and notes in `_(...)_` form. A fresh template has only those, so it reports nothing.
4. **Report.** If everything resolves, print one line: `Audit: all values resolve.` Otherwise list the findings. Either way end with one line that says what was not checked. Print it word for word, as the last line of the audit: `Not checked: header text, test filters, whether commands work.` Nothing follows it.

### Hints

Two notes about rows that already have a value. Both read files only. Never edit project code.

1. **Scenarios with no steps yet.** Say this only when `package.json` lists `playwright-bdd` and the Playwright config does not set `missingSteps`. Search the config file before you say it. The hint is shown only when the setting is absent. Say: Playwright-BDD's `generate` step fails on scenarios that have no steps yet, such as the `@pending` scenarios `design` writes in `specify-only` mode. Setting `missingSteps: 'fail-on-run'` in the Playwright config moves that failure to run time, and `run` already skips the unautomated tag. Do not suggest a tag filter on the `generate` command: `implement` must generate the scenario it is working on, and that scenario keeps its tag until the verifier passes. For any other framework say nothing. The setting is verified for Playwright-BDD only.
2. **Decision log.** The one exception to never changing a filled row. When the `decision_log` row is `off` and `decisions_dir` holds no decision files (no `*.jsonl`), ask with `"AskUserQuestion"`: "Turn the decision log on?" Write `on` into the value cell of that row only with approval, using `"Edit"`. If the row is `on`, or decision files exist, say nothing. Do not remember a refusal: ask again on the next run. Change no other filled row.

### Skill roles

The Skill Roles table has two placeholder roles, `domain-knowledge` and `requirements-sync`. Projects often already have their own skills for them. Propose these together with the other rows, and write them only on approval, like any other row. Never change a role that already has a value.

1. **Find candidates.** List the skill files in `.claude/commands/` and `.claude/skills/`. Read only the name and the one-line description in each header. Do not read skill bodies, and do not look in `~/.claude/` or in other plugins.
2. **Skip the installer's files.** A file with the `# Source: https://github.com/godrose/bdd-skills` line is the installer's copy of a plugin skill. It is never a candidate. The same goes for the files listed under Leftovers.
3. **Match.** `domain-knowledge` fits a skill about the project's selectors, patterns or gotchas, often named `*-knowledge`. `requirements-sync` fits a skill that fetches stories from, or publishes results to, an issue tracker or test-management tool, often named `*-sync`. A name hint raises confidence. A description that clearly fits can match on its own, at lower confidence.
4. **Propose.** Give the skill name, the evidence (its file and description) and a confidence. If several skills fit one role, propose the best one and name the runners-up in the evidence. The table holds one skill per role.
5. **Nothing found.** Leave the row as it is. Write `no local skill found for <role>` and name the places you searched. The role is optional.

### Leftovers

Projects that used the project-file install may hold copies of the skills next to the plugin, which gives duplicate commands. Report them. Do not delete anything.

1. **Find them.** Run:

   ```
   grep -l "^# Source: https://github.com/godrose/bdd-skills" .claude/commands/bdd-*.md .claude/agents/bdd-*.md 2>/dev/null
   find .claude -maxdepth 2 \( -name decisions.sh -o -name decision.schema.json \) 2>/dev/null
   ```

   The installer writes the `# Source:` line into every skill file it creates. Also count a file as a leftover when it is named `.claude/commands/bdd-<name>.md` with name one of discover, design, implement, run, triage or reconcile, or `.claude/agents/bdd-<name>.md` with name verifier, even without the line (older installs). The old names `bdd-scenario-design`, `bdd-implement-scenario` and `test-feature` (as `.claude/commands/<name>.md`) count by name alone, because the installer removes them itself. A file counts only if it exists on disk. A file that git shows as deleted is not a leftover, because it causes no duplicate command.

2. **Report.** If there are none, say nothing about it. Otherwise list each leftover and say the plugin provides the same commands under `bdd:`, so the old files can be deleted by hand. Any other `bdd-*` file in `.claude/commands/` matches no rule, so its owner cannot be proved. Report it as "origin unknown, left alone". Do not call it the user's own skill. If `.claude/.gitignore` has a comment that says the files were installed from `https://github.com/godrose/bdd-skills`, mention it next to these files as a hint only. It never classifies a file. Remind the user that the Skill Roles table in `.claude/bdd-config.md` should name `bdd:design` and the other plugin skills.

### Rules

- Never overwrite `.claude/bdd-config.md`, and never change a row that already has a value, except `decision_log` with approval: see Hints.
- Without `--detect`, do not fill in any value.
- Writes nothing until the user approves it.
- Do not run the project's commands, builds or tests. Read files only.
- Do not delete or edit the leftover files. Only report them.
- Do not commit.

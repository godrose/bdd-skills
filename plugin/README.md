# bdd

BDD workflow skills for Claude Code. They take a story from discussion to scenarios that pass, in any test framework.

- `/bdd:discover` looks at what the project already has, then asks one question at a time, finds the edge cases and writes a discovery pack.
- `/bdd:design` turns acceptance criteria into scenarios, audits step reuse, checks that each scenario asserts what its title says and that the setup it needs exists, and lints the draft before you see it. You approve the scenarios.
- `/bdd:implement` writes the step code, sees each scenario fail for the stated reason, then pass.
- `/bdd:run` runs scenarios and never counts a run with zero tests as a pass.
- `/bdd:deliver` carries a change from a plain description to verified scenarios in one conversation. It uses the commands above, asks for two approvals, looks at the real result, and ends with a report in plain words that says what passed, failed or could not be checked.
- `/bdd:triage` and `/bdd:reconcile` keep an optional decision log in step with the scenarios.
- `/bdd:init` sets up and audits the project config, `bdd-config.md`.

Install:

```
/plugin marketplace add godrose/bdd-skills
/plugin install bdd@gennadyverdel-plugins
```

The plugin reads and writes only files in your project. It has no hooks and no MCP server, and it makes no network calls itself. If you configure a requirements-sync skill, `/bdd:design` can call it to read a tracker item. It also runs the test, lint and generate commands that you put in `bdd-config.md`.

The full guide, the config reference, the changelog and the list of known gaps are in the repository: https://github.com/godrose/bdd-skills

## Tool permissions

The commands pre-approve nothing. Claude Code asks before each shell command and each file write, unless your own settings allow them. The commands run the test, lint, generate and prepare commands from `bdd-config.md`, and write the files in the folders that file names. `design` writes no scenarios and `init` writes no config values until you approve them. The decision log script is not part of this plugin. It comes with the project-file install, and the plugin says so when it needs it. The list of known gaps is in [known-gaps.md](https://github.com/godrose/bdd-skills/blob/main/docs/known-gaps.md).

Licensed under Apache-2.0.

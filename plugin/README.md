# bdd

BDD workflow skills for Claude Code. They take a story from discussion to scenarios that pass, in any test framework.

- `/bdd:discover` asks the questions, finds the edge cases and writes a discovery pack.
- `/bdd:design` turns acceptance criteria into scenarios, audits step reuse and lints the draft before you see it. You approve the scenarios.
- `/bdd:implement` writes the step code, sees each scenario fail for the stated reason, then pass.
- `/bdd:run` runs scenarios and never counts a run with zero tests as a pass.
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

The commands pre-approve `Bash`, and some also pre-approve `Write` and `Edit`. They do this because they run the commands you put in `bdd-config.md` (prepare, generate, test and lint), and those differ for each project, so a fixed list cannot name them. Apart from those, the plugin's own shell use is its `decisions.sh` script, `git merge-base`, and in `init` a file copy and a `find` over `.claude`. File writes go to the folders that `bdd-config.md` names. `design` writes no scenarios and `init` writes no config values until you approve them. The grants are listed in [known-gaps.md](https://github.com/godrose/bdd-skills/blob/main/docs/known-gaps.md).

Licensed under Apache-2.0.

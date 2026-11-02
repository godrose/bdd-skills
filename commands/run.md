---
description: "Run BDD feature tests — select environment, scenarios by tag/name/suite, inspect results"
allowed-tools: ["Agent", "Bash", "Read", "Write", "Grep", "Glob", "AskUserQuestion"]
---

## Test Feature — Run BDD Scenarios

Run BDD feature tests against any configured environment. Framework-agnostic - reads tooling commands and conventions from `.claude/bdd-config.md`. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

### Input

The user provides one or more of:
- A suite tag (e.g., `@smoke`, `@deep`, `@e2e`)
- An individual scenario tag (e.g., `@login`, `@analytics`)
- A scenario name or partial match (e.g., "pipeline sanity", "schema")
- A feature file path
- A project name (e.g., `--project e2e`)
- "all" to run everything

### Step 1: Read Project Config

Read `.claude/bdd-config.md` for:
- **prepare** command (optional)
- **generate** command
- **test** command
- **features_dir** — where to scan for scenarios
- **test_results_dir** — where to find artifacts
- **error_context** — path pattern for failure details (if available)

### Step 2: Environment Selection

If the project supports multiple environments, ask the user which one to target (unless already specified or there's only one). Check for environment config files in the project (e.g., env config, `.env` files, appsettings, build configurations). Default to the primary/dev environment.

### Step 3: Discover Available Scenarios

If the user's intent is ambiguous, scan the **features_dir** for available scenarios:

```
Search for "Scenario" and "Scenario Outline" in *.feature files
```

For tag discovery:
```
Search for lines starting with @ in *.feature files
```

Present matching scenarios and ask the user to confirm.

### Step 4: Project Auto-Detection

If the test framework supports multiple projects/configurations, read the **config_file** to determine which project matches the user's scenario. Look for tag-based routing, test match patterns, or build configurations.

If unclear, ask the user or use the default project.

### Step 5: Prerequisites

Before running, verify:

1. **Dependencies** — check if the project's dependency directory exists (e.g., `node_modules/`, `bin/`, `packages/`). Run the install command if missing.
2. **Prepare** - run the **prepare** command from bdd-config, before code generation. It builds what the tests launch but the generate and test commands do not (for example server executables). If the row is absent, empty, still in `<...>` form, or a note such as `_(not needed)_`, skip this step and say so. That is not a failure. If **prepare** fails, report the error and stop. Do not run generate or test.
3. **Code generation** - run the **generate** command from bdd-config. If the row is empty, still in `<...>` form, or a note such as `_(not needed)_`, skip this step and say so. That is not a failure: some frameworks read `.feature` files directly. If the command fails, report the error and stop.
4. **Auth/environment state** - check if the environment requires authentication setup, credentials, or external services. Look for auth state files or config referenced by the project.
5. **Environment-specific prereqs** - check if the feature's Background or preconditions require special setup (e.g., SSO login, VPN, database seeding, server startup).

### Step 6: Run Tests

Run the **test** command from bdd-config with the appropriate filter flags for the framework:

- **By tag** — pass the tag as a filter argument
- **By scenario name** — pass as a name/grep filter
- **Multiple scenarios** — combine filters with OR logic
- **Single feature file** — pass the file path
- **All** — run without filters

The exact flag syntax depends on the framework (read from test command conventions or config_file).

**Planned and manual-only scenarios.** Scenarios tagged with the **unautomated_tag** (default `@pending`) or the **manual_only_tag** (default `@manual-only`) have no step definitions on purpose. Exclude both from the run. Undefined steps under either marker are expected and never an error.

### Step 7: Results

**On success:**
- Report pass count and total duration
- Open the test report if the framework generates one

**On failure, collect evidence** using the priority chain:
1. **Error context file** — if **error_context** is configured, read it for the failed test
2. **Test results directory** — check **test_results_dir** for artifacts (screenshots, traces, logs, TRX files)
3. **Test runner stdout** — parse the failure output for step name, error message, and stack trace

**Report the outcome:**
- Which scenarios passed/failed
- For failures: the step that failed, the error message, and key context from the evidence
- Suggest next steps: re-run with verbose/headed mode for debugging, or invoke the **implementer** skill to fix

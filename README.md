<div align="center">

<pre>
 _          _      _  
| |__    __| |  __| |
| '_ \  / _` | / _` |
| |_) || (_| || (_| |
|_.__/  \__,_| \__,_|
</pre>

# BDD Skills for Claude Code

**🥒 Agree the examples first, then automate them**
*A Claude Code plugin that takes a story through discussion, scenarios and step definitions to a verified run. Works with Playwright-BDD, SpecFlow, Cucumber or any Gherkin runner.*

[![CI](https://github.com/godrose/bdd-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/godrose/bdd-skills/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Stars](https://img.shields.io/github/stars/godrose/bdd-skills?style=flat)](https://github.com/godrose/bdd-skills/stargazers)
[![PRs welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#contributing)

<img src="docs/demo/deliver.gif" alt="Terminal recording: /bdd:deliver takes one sentence to verified scenarios on a small demo app" width="800" />

<sub>A real /bdd:deliver session, cut for length: one sentence in, a plain-words report out. The same flow [step by step](docs/demo/story.gif): triage, design, implement.</sub>

</div>

<br />

## Contents

- [New to BDD?](#new-to-bdd)
- [Before you start](#before-you-start)
- [Quick start](#quick-start)
- [The flow](#the-flow)
- [Modes](#modes)
- [Install](#install)
- [Configure](#configure)
- [Decision log](#decision-log)
- [What's included](#whats-included)
- [Update](#update)
- [Glossary](#glossary)
- [Related projects](#related-projects)
- [Contributing](#contributing)
- [License](#license)

## New to BDD?

**BDD** (behaviour-driven development) means agreeing on examples of how a feature should behave, in words everyone understands, before anyone builds it. The examples then become automated checks.

A **scenario** is one such example. It is written in **Gherkin**, a plain-text format with three keywords: `Given` is the starting point, `When` is what the user does, and `Then` is what they should see. Scenarios live in `.feature` files.

```gherkin
Feature: Cancel an order
  Scenario: A customer cancels an order that has not shipped
    Given an order that has not shipped
    When the customer cancels it
    Then the order shows as cancelled
    And the customer sees a refund notice
```

A **step definition** is the code behind one line of a scenario. It makes that line run against your app. A **runner** finds the `.feature` files and runs the step definitions. Other words you will meet are in the [Glossary](#glossary).

This plugin finds the examples by asking you questions, then writes the scenarios and the step definitions and runs them.

## Before you start

You need four things:

- **Claude Code.**
- **A project to work on.** It can be an app that already exists.
- **A branch.** The plugin edits files in your project, tests and application code. Work on a branch and read the diff before you merge.
- **A Gherkin runner.** The plugin does not install one. If your project has none, pick one for your stack first:

| Stack | Runner |
|-------|--------|
| A web app tested through a browser with Playwright | [Playwright-BDD](https://vitalets.github.io/playwright-bdd/) |
| Any other JavaScript project, or Java, Kotlin or Ruby | [Cucumber](https://cucumber.io/docs/installation/) |
| .NET | [Reqnroll](https://reqnroll.net/), the successor of SpecFlow |

Not listed? Any Gherkin runner works, for example Behave (Python), Behat (PHP) or godog (Go). Put its commands in the config rows.

Set the runner up as its own documentation says, then run one example: follow the runner's own getting-started page until its example passes. Then come back here. `/bdd:init --detect` reads your build files and proposes the config.

## Quick start

In Claude Code:

```
/plugin marketplace add godrose/bdd-skills
/plugin install bdd@gennadyverdel-plugins
```

Three names, one project:

- `godrose/bdd-skills` is the repository.
- `gennadyverdel-plugins` is the marketplace, the catalog the repository publishes.
- `bdd` is the plugin, so its commands are `/bdd:*`. `bdd@gennadyverdel-plugins` means the plugin `bdd` from that marketplace.

Then, once in each project:

```
/bdd:init --detect
```

This creates `.claude/bdd-config.md` and proposes values for it from your build files, CI and `.feature` files. It writes only the rows you approve. Plain `/bdd:init` copies the template and fills in nothing.

In a headless run (`claude -p`), writes into `.claude/` may be refused. `/bdd:init` then prepares the file and prints the command to run. Run it yourself, or approve the write in an interactive session.

> 💡 **Tip:** Commit `.claude/bdd-config.md` once it is filled in, so the whole team shares one setup.

Then give it a story. For a first run, in one conversation:

```
/bdd:deliver <description>
```

Or step by step, with a stop between steps (see The flow):

```
/bdd:discover <story>
```

## The flow

### Which path?

- **One conversation, first run:** `/bdd:deliver <description>`. It asks, shows the agreed examples, then the scenarios, builds and checks them, and reports in plain words.
- **Step by step, with a stop between steps:** `/bdd:discover`, `/bdd:design` and `/bdd:implement`. Add `--specify-only` to stop at the scenarios (see Modes).

Either path suits a developer. A first run is easier with `deliver`.

Step by step:

1. `/bdd:discover <story>` first looks at what the project already has, then asks one question at a time and finds examples, edge cases and exclusions. Trivial changes skip it.
2. `/bdd:design` shows the scenarios in plain words, with a reuse audit of every step. It checks that each scenario asserts what its title claims, and that the setup a scenario depends on is checked. You approve them.
3. `/bdd:implement` automates the scenarios and `bdd:verifier` checks them.

The agreed scenarios become automated checks, so later changes cannot silently break them.

> 🧪 **Trivial change?** A one-line fix, a rename or a copy edit skips discovery. The plugin says so in one sentence and moves on.

`/bdd:deliver <description>` runs the four steps in one conversation. It is written for a product manager with a developer watching, and a developer can use it too. It asks one question at a time, shows the agreed examples for approval, then the scenarios for a go-ahead, implements them, and ends with a report in plain words: each example passed, failed or couldn't be checked, and whether the earlier scenarios of the same feature still pass. It uses the commands above and does not replace them. Answers that shaped a scenario are written beside it in the `.feature` file. Exclusions and removals go in one list, `docs/out-of-scope.md`, so the next description is not asked for what was ruled out.

If you run a command before `/bdd:init`, it stops and tells you to run it.

### What you get

`/bdd:implement` and `/bdd:deliver` write the step definitions and the support code, run the scenarios, and build the feature in your app until they pass. A scenario for a feature that does not exist yet fails first, on an assertion. That red is expected: it shows the scenario can fail, and the plugin checks for it (red-first). The scenario turns green when the feature works.

Each `Given` step in a scenario needs code that puts your app in that state, such as an order that has not shipped. `/bdd:implement` writes it, using how your tests and app already create data: an API call, a database helper or a page step. For state that something else provides, such as a seeded user or a deployed service, the scenario gets a step that checks it is there and fails with a setup error when it is not.

If your company has its own way of writing application code, name that skill in the `feature-builder` row of the Skill Roles table in `.claude/bdd-config.md`. The plugin then asks it to write the application code. You can also name a skill in your request, for example "use our X skill for the code", and the plugin uses it for that run without any config. Without either, the plugin makes the smallest change that turns the scenario green and lists the files it changed.

## Modes

The default mode is `specify-and-implement`. For teams there is `specify-only`: design and approve the scenarios, then stop. The scenarios are written as `.feature` files and tagged `@pending`, or `@manual-only` when a scenario stays manual by design. A product manager can review them in a pull request before any automation exists. Automate them later with `/bdd:implement`.

`/bdd:run` and `bdd:verifier` skip scenarios tagged `@pending` or `@manual-only`, and undefined steps under those tags are never an error.

> 💡 **Playwright-BDD:** its `generate` step still fails on scenarios that have no steps yet. Set `missingSteps: 'fail-on-run'` in your Playwright config so a `specify-only` branch stays green. `/bdd:init --detect` and `/bdd:design` tell you when it is missing.

Choose the mode with the `workflow_mode` row in `.claude/bdd-config.md`, or per run with `--specify-only` or `--specify-and-implement`. If the row is absent, the default applies.

## Install

There are two ways to install. The plugin is the recommended one.

### As a plugin

The commands are in the Quick start. On Claude Code 2.1.275 or later, one step also works: `/plugin install bdd --marketplace godrose/bdd-skills`.

The plugin namespaces its commands: `/bdd:discover`, `/bdd:design`, `/bdd:implement`, `/bdd:run`, `/bdd:triage`, `/bdd:reconcile` and `/bdd:deliver`.

A plugin cannot create files in your project, so run `/bdd:init --detect` once in each project. It copies the template to `.claude/bdd-config.md` and proposes values for it. Claude Code may ask you to approve the copy, because it writes into `.claude/`. Plain `/bdd:init` copies the template and fills in nothing, so you open the file and fill in the commands and paths yourself, as described under Configure. Neither form overwrites an existing config. Commit the file once it is filled in.

With `--detect`, it reads your build files, CI workflows, README and `.feature` files, and proposes a value for each placeholder row, with the file it came from and a confidence level. It writes only the rows you approve, never changes a row that already has a value, never runs your commands, and says `unknown` where the files do not answer. Check the commands it proposes before you rely on them. It also proposes your own skills for the `domain-knowledge` and `requirements-sync` roles, matched by the name and one-line description in `.claude/commands/` and `.claude/skills/`. If several fit, it names the runners-up, and if none fit, it leaves the row alone. It is plugin only.

`/bdd:init` also lists leftover project-file copies of the skills, which give duplicate commands next to the plugin. It only reports them and never deletes. The installer's files are found by the `# Source:` line it writes, and by the old command names it replaced. A `bdd-*` file that matches neither is reported as "origin unknown, left alone".

With `--detect`, the command also audits the values already in your config. It reports paths that do not exist and skill roles that do not resolve, and it never edits them.

> 🔒 **Never deletes:** `/bdd:init` only reports leftovers and bad values. You decide what to remove or fix.

<details>
<summary><b>As project files</b></summary>

Use this when you do not want a plugin, or when you want the skills committed in your repo.

```bash
# Remote install (no clone needed):
curl -sL https://raw.githubusercontent.com/godrose/bdd-skills/main/install.sh | bash -s -- /path/to/your/project

# Or from a local clone:
git clone https://github.com/godrose/bdd-skills.git /tmp/bdd-skills
/tmp/bdd-skills/install.sh /path/to/your/project
```

This copies the skills into `.claude/` with source headers (repo URL + commit hash) and creates `bdd-config.md` from the template. Commit the result. The repo is self-contained after install.

Project files have no plugin namespace, so the commands use a hyphen: `/bdd-discover`, `/bdd-design`, `/bdd-implement`, `/bdd-run`, `/bdd-triage`, `/bdd-reconcile` and `/bdd-deliver`. Everything else in this README applies to both ways. Where it says `/bdd:design`, type `/bdd-design`.

</details>

<details>
<summary><b>Moving from project files to the plugin</b></summary>

1. Install the plugin as above.
2. Delete the files the installer created, and only these: `.claude/commands/bdd-discover.md`, `bdd-design.md`, `bdd-implement.md`, `bdd-run.md`, `bdd-triage.md`, `bdd-reconcile.md` and `bdd-deliver.md` in that folder (delete `bdd-deliver.md` only if its first lines carry the installer's `# Source:` header, because the installer keeps a file of your own with that name), plus `.claude/agents/bdd-verifier.md`, `.claude/scripts/decisions.sh` and `.claude/schemas/decision.schema.json`. Some may not exist, because older installs did not have every file. That is fine. Having both sets gives you duplicate commands.
   Keep your own skills, such as `bdd-<project>-knowledge.md` or a sync skill. They are not part of the plugin.
3. Keep `.claude/bdd-config.md`. In its Skill Roles table, change `bdd-design` to `bdd:design`, and the same for the other skills and the verifier.
4. Tell the maintainer if you still need the project-file install. It stays for a few releases.

</details>

## Configure

Edit `.claude/bdd-config.md` in your project, or let `/bdd:init --detect` propose the values. Skills reference each other by **role** (from the Skill Roles table in that file), not by name, so you swap an implementation by editing the config. If your step code sits in more than one folder, list them in `steps_dir`, comma-separated, for example `src/Steps, src/Adapters`.

### Minimum to start

A first run needs these rows in `.claude/bdd-config.md`. Every other row is optional and has a default.

| Row | What to put |
|-----|-------------|
| `test` | The command that runs your scenarios |
| `features_dir` | The folder that holds your `.feature` files |
| `steps_dir` | The folder that holds your step definitions |
| `config_file` | The runner's config file |
| `generate` | The command that turns `.feature` files into test files. Leave it empty if your runner reads them directly |
| `typecheck` | The command that checks types or compiles with strict warnings. Leave it empty if there is none |
| `prepare` | Only if the tests need something built or started first, such as a server |

For a small Playwright-BDD project, the rows look like this:

```markdown
| test | `npx playwright test` |
| generate | `npx bddgen` |
| typecheck | `npx tsc --noEmit` |
| features_dir | `features` |
| steps_dir | `steps` |
| config_file | `playwright.config.ts` |
```

### More settings

<details>
<summary><b>Tooling rows by framework</b></summary>

Drop one of these row sets into the **Tooling** table (the template ships with the column headers already in place):

**Playwright-BDD (TypeScript):**
```markdown
| generate | `npx bddgen` |
| test | `npx playwright test` |
| typecheck | `npx tsc --noEmit --noUnusedLocals --noUnusedParameters` |
```

**SpecFlow or Reqnroll (C#/.NET):**
```markdown
| generate | `dotnet build` |
| test | `dotnet test --no-build` |
| typecheck | `dotnet build -warnaserror --no-incremental` |
```
If your project builds with a named configuration, add `-c <configuration>` to all three.

**Cucumber (Java/Kotlin, Maven):**
```markdown
| test | `mvn test` |
| typecheck | `mvn compile -Dmaven.compiler.failOnWarning=true -Dmaven.compiler.showWarnings=true` |
```
Leave `generate` empty: Cucumber reads the `.feature` files itself. Check that your version of the Maven compiler plugin honors the warning options.

</details>

<details>
<summary><b>Optional config rows</b></summary>

Every row below is optional. If a row is absent, the default applies.

| Row | Default | Purpose |
|-----|---------|---------|
| `workflow_mode` | `specify-and-implement` | `specify-only` stops after the approved scenarios |
| `unautomated_tag` | `@pending` | Tag for scenarios planned to be automated (v1 default was `@manual`) |
| `manual_only_tag` | `@manual-only` | Scenarios that stay manual by design |
| `status_scope` | `scenario` | Where the planned marker sits: `scenario`, `feature` or `directory` |
| `blocked_tag` | none | Scenarios waiting on the product |
| `planned_dir`, `manual_only_dir` | none | Path components that mark status with directory scope |
| `decision_log` | `off` | `on` records decisions in `decisions_dir`. `/bdd:init --detect` asks whether to turn it on |
| `decisions_dir` | `docs/decisions` | Where the decision log lives |
| `scenario_id_prefix` | `spec-` | Prefix of the stable scenario id tag |
| `automated_tag` | none | Tag your test-management tool keys on, added when a scenario is automated |
| `glossary_file` | none | Domain terms for the vocabulary check |
| `lint` | none | Project linter for tags, casing and indentation. `design` runs it on the draft before showing it, using a temp `.bdd-draft-*` file in `features_dir`. It acts only on findings in the draft, and warns and continues if the linter cannot run |
| `prepare` | none | Command that builds what the tests launch, run before generate and test |
| `step_batch` | `auto` | Steps per test run in `implement`: `auto` groups by risk, or `1`, a number or `all` |
| `discovery_dir` | `docs/discovery` | Where a saved discovery pack goes |
| `out_of_scope_file` | `docs/out-of-scope.md` | Where `/bdd:deliver` and `/bdd:discover` list what was excluded or removed, one line each |

</details>

<details>
<summary><b>Optional skills (project-specific)</b></summary>

The plugin does not include these. Create them in your project's `.claude/commands/`:

- **Domain knowledge** (`bdd-<project>-knowledge.md`): project-specific selectors, patterns, gotchas
- **Requirements sync** (`bdd-jira-sync.md`, `bdd-azdo-sync.md`, etc.): fetch ACs from issue tracker, publish results

Register them in `bdd-config.md` under Skill Roles.

</details>

## Decision log

Opt in with `decision_log` set to `on`. Each story gets a file, `docs/decisions/<story>.jsonl`, with one JSON record per line. A record says what was decided, why, which scenarios it adds, changes or removes, and links to where it was agreed (Slack, Jira, a pull request). Records are append-only. A change of mind is a new record that supersedes the old one. Git is the source of truth. Jira and your test-management tool only show it.

The log needs `jq`. Add `docs/decisions/*.jsonl merge=union` to `.gitattributes` so parallel branches can append to one file.


The script that checks the log, `decisions.sh`, comes with the project-file install (`install.sh`). The marketplace plugin does not ship it, because the directory refuses scripts. With the plugin alone, `design` and `triage` go on without records and say so, and `reconcile` says it needs the project install.

Each scenario in the log carries a stable tag such as `@spec-export-empty-list`. Scenarios without one are legacy and not tracked. They get an id the first time a decision touches them.

<details>
<summary><b>Feedback intake, reconcile and the story page</b></summary>

**Feedback intake.** Each story has one channel for discussion. Paste that text into `/bdd:triage <story>`. The skill classifies each message as approve, change, question or unclear, proposes scenario edits and records, and writes nothing until you approve each item. Unclear never counts as approval.

**Reconcile.** `/bdd:reconcile` runs `decisions.sh check` and reports orphans, drift, undecided scenarios and conflicts. It is a report, not a sync, and it never edits anything. The same check can run in CI or a pre-push hook.

**Story page.** `decisions.sh show <story>` prints a read-only story page in Markdown for product managers: what was agreed (with a status: automated, planned, checked by hand or waiting on the product), what was left out or postponed, what is still open, and the history. With `--since <ref>` it lists what changed since you last looked. Paste it into Jira, Confluence or Slack.

</details>

## What's included

<details>
<summary><b>Files</b></summary>

```
.claude-plugin/
  marketplace.json              # Marketplace listing for this repo. Its source is ./plugin
.github/                        # CI workflows, the pull request template, code owners and Dependabot
plugin/                         # The plugin. Claude Code installs this folder
  .claude-plugin/
    plugin.json                 # Plugin manifest: name, version, description
    icon.png                    # The listing icon for the plugin directory
  commands/
    init.md                     # Plugin only: create .claude/bdd-config.md from the template (copy only)
    discover.md                 # Discover what to build: questions, examples, edge cases, exclusions
    design.md                   # Design scenarios from ACs - analyze gaps, formulate, implement
    implement.md                # Implement step definitions and build the feature - explore, discover selectors, verify
    run.md                      # Run tests by tag/name/suite - config-driven, any framework
    triage.md                   # Turn pasted channel discussion into scenario edits and decision records
    reconcile.md                # Report drift between the decision log and the scenarios
    deliver.md                  # Carry a change from a description to verified scenarios in one conversation
  agents/
    verifier.md                 # Run tests + type check, report results (read-only, no edits)
  bdd-config.template.md        # Project config template - fill in your tooling and conventions
  README.md                     # The plugin's listing text
  LICENSE                       # A copy of the licence, so the plugin folder is complete on its own
scripts/decisions.sh             # Check, fingerprint, status and story page for the decision log (needs jq). Copied by install.sh
schemas/decision.schema.json    # Record schema read by decisions.sh. Copied by install.sh
evals/                          # Eval cases and evals/run.sh. Not part of the plugin
flows/                          # Scripted runs of a whole discover or deliver conversation, with small fixture projects. Run by hand
install.sh                      # Copy the skills into a project's .claude/ directory as bdd-<name> files
specs/                          # The repo's own specification: scenarios in specs/features, their steps in specs/steps
tests/                          # The test runner, the CI scripts, and tests/mutate.sh with its breaks in tests/mutations/
package.json, tsconfig.json, cucumber.js  # The scenario runner (Cucumber and tsx), its config and its typecheck
docs/                           # Discovery packs, trial records, the known gaps, the demo recording
README.md                       # This file
CHANGELOG.md                    # What each release changed
CLAUDE.md                       # How to work on this repo, including releasing
LICENSE                         # Apache 2.0
```

</details>

<details>
<summary><b>Architecture</b></summary>

```
bdd:discover (optional first step: questions, examples, edge cases)
  └─ hands a discovery pack to:
bdd:design (methodology: what scenarios to create)
  ├─ Discovers: requirements-sync skill (fetch ACs, optional)
  ├─ Invokes:   implementer skill (implement each scenario)
  │               ├─ Discovers: domain-knowledge skill (project patterns, optional)
  │               ├─ Discovers: feature-builder skill (writes application code, optional)
  │               └─ Dispatches: verifier agent (run tests + type check)
  └─ Discovers: requirements-sync skill (publish results, optional)

bdd:triage (optional: channel discussion to approved edits and decision records)
bdd:reconcile (optional: report drift between the decision log and the scenarios)
bdd:deliver (composes discover, design, implement and run: two approvals, a report in plain words)
```

Skills reference each other by **role** (from `bdd-config.md`), not by name. The optional roles `reconciler` and `feedback-intake` point at `bdd:reconcile` and `bdd:triage`. The optional role `feature-builder` points at your own skill for application code.

With the decision log on, `bdd:triage` turns channel discussion into approved edits and records, and `bdd:reconcile` reports drift (neither runs tests).

In `specify-only` mode, `bdd:design` stops after the scenarios. `bdd:implement` runs later, once they are approved.

</details>

## Update

**Plugin.** The plugin is versioned, and a change reaches you when a new version is released. [`CHANGELOG.md`](CHANGELOG.md) lists what each version changed. Update to get the latest release:

```bash
claude plugin marketplace update gennadyverdel-plugins
claude plugin update bdd@gennadyverdel-plugins
```

Restart Claude Code to apply the update.

A fresh install gets `main` as it is at that moment, which can be newer than the last release. A release is what the tag and the changelog name.

**Project files.** Re-run the install script. Your `bdd-config.md` won't be overwritten. The installer prints a note for each newer row your config lacks, with its default.

```bash
cd /tmp/bdd-skills && git pull
/tmp/bdd-skills/install.sh /path/to/your/project
```

## Glossary

### BDD

- **Acceptance criteria** (ACs): the conditions a story must meet to count as done.
- **Red-first**: seeing a scenario fail for the reason it states before it passes. A green that was never seen red proves little. The plugin checks it for every scenario it implements.

### This plugin

- **Discovery pack**: the saved record of a `/bdd:discover` conversation: questions, examples, edge cases, exclusions and decisions. It goes to the folder in the `discovery_dir` row.
- **Reuse audit**: the check of each step of a draft scenario against the step definitions that already exist, so no duplicate is added.
- **Skill role**: a job in the Skill Roles table of `.claude/bdd-config.md`, such as designer, verifier or feature-builder. A command looks up the skill for a role there and not by name, so you can swap in your own skill.
- **Specify-only**: a mode that stops after the scenarios are approved and written, so a product manager can review them before any automation exists. See Modes.
- **Pending and manual-only tags**: `@pending` marks a scenario planned to be automated and not yet. `@manual-only` marks one that stays manual by design. `/bdd:run` and the verifier skip both.

### Decision log (opt-in)

- **Decision log**: with `decision_log` set to `on`, one file per story records what was decided and why, and which scenarios the decision adds, changes or removes. `/bdd:triage` writes to it and `/bdd:reconcile` reads it. See Decision log.
- **Drift**: a scenario that changed since its last decision.
- **Orphan**: a decision that points at a scenario that is gone.
- **Undecided**: a scenario with a stable id tag and no live decision.
- **Conflict**: two live decisions that supersede the same record.

### Claude Code

- **Marketplace**: a catalog of plugins that Claude Code installs from. This repo publishes one, `gennadyverdel-plugins`.
- **Headless run**: a run of `claude -p`, without an interactive session.

## Related projects

The plugin works with these BDD tools:

- [Playwright-BDD](https://github.com/vitalets/playwright-bdd) - run Gherkin features on Playwright.
- [Cucumber](https://github.com/cucumber/cucumber-js) - the reference Gherkin runner for JavaScript.
- [Reqnroll](https://github.com/reqnroll/Reqnroll) - BDD for .NET, the open-source successor to SpecFlow.

## Contributing

Contributions from individuals and from teams are welcome. No sign-off form is needed. Under the Apache License 2.0, what you contribute is licensed the same way as the rest of the repo, unless you say otherwise.

- Look for issues labeled `good first issue` or `help wanted`, or open an issue with your idea first.
- This repo uses its own method. A larger change (a new command, a config row, anything in install) starts with a discovery pack in `docs/discovery/`. A small fix, rename or copy edit does not. [`CLAUDE.md`](CLAUDE.md) has the details.
- Install the scenario runner once with `npm ci`. Run `bash tests/run.sh` before you open a pull request, and `bash tests/ci_local.sh` before you push: it runs what CI runs and names the step that failed. A new test must fail before your change and pass after it.
- To see whether the tests notice a change, break the code on purpose with `tests/mutate.sh` (usage in its header). It breaks copies and never your checkout, and it runs by hand.
- To watch a whole `discover` or `deliver` conversation in a real session, use `flows/run.sh` (see [`flows/README.md`](flows/README.md)). It runs by hand, after `npm ci`, and uses your plan limit.
- Try the plugin from a clone with `claude --plugin-dir <clone>/plugin`. Check it with `claude plugin validate plugin` and run its evals with `bash evals/run.sh`.
- Fill in the pull request template.
- What the plugin does not check is listed in [`docs/known-gaps.md`](docs/known-gaps.md). When you close a gap, remove its entry in the same change.

## License

[Apache License 2.0](LICENSE). Use it, change it and ship it in commercial or open projects.

Copyright 2026 Gennady Verdel

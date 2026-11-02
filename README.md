# BDD Skills for Claude Code

Agree the examples first, then automate them. A Claude Code plugin that takes a story through discussion, scenarios and step definitions to a verified run. Framework-agnostic: works with Playwright-BDD, SpecFlow, Cucumber, or any Gherkin runner.

## Contents

- [Quick start](#quick-start)
- [The flow](#the-flow)
- [Modes](#modes)
- [Install](#install)
- [Configure](#configure)
- [Decision log](#decision-log)
- [What's included](#whats-included)
- [Update](#update)

## Quick start

You need read access to this repository. It is private for now, so see Access under Install.

In Claude Code:

```
/plugin marketplace add godrose/bdd
/plugin install bdd@godrose-plugins
```

Then, once in each project:

```
/bdd:init --detect
```

This creates `.claude/bdd-config.md` and proposes values for it from your build files, CI and `.feature` files. It writes only the rows you approve. Plain `/bdd:init` copies the template and fills in nothing.

Then start with a story:

```
/bdd:discover <story>
```

## The flow

For an individual builder:

1. `/bdd:discover <story>` asks one question at a time and finds examples, edge cases and exclusions. Trivial changes skip it.
2. `/bdd:design` shows the scenarios in plain words, with a reuse audit of every step. You approve them.
3. `/bdd:implement` automates the scenarios and `bdd:verifier` checks them.

The agreed scenarios become automated checks, so later changes cannot silently break them.

If you run a command before `/bdd:init`, it stops and tells you to run it.

## Modes

The default mode is `specify-and-implement`. For teams there is `specify-only`: design and approve the scenarios, then stop. The scenarios are written as `.feature` files and tagged `@pending`, or `@manual-only` when a scenario stays manual by design. A product manager can review them in a pull request before any automation exists. Automate them later with `/bdd:implement`. `/bdd:run` and `bdd:verifier` skip scenarios tagged `@pending` or `@manual-only`, and undefined steps under those tags are never an error.

Choose the mode with the `workflow_mode` row in `.claude/bdd-config.md`, or per run with `--specify-only` or `--specify-and-implement`. If the row is absent, the default applies.

## Install

There are two ways to install. The plugin is the recommended one.

**Access.** The repository is private for now. You need read access to it and git credentials on your machine: an SSH key loaded in `ssh-agent`, or HTTPS with a stored credential (`gh auth login`, then `gh auth setup-git`). Claude Code uses your own git setup and has no token of its own. The one-line `curl` install below only works once the repository is public. Until then, use the clone form.

### As a plugin

The commands are in the Quick start. On Claude Code 2.1.275 or later, one step also works: `/plugin install bdd --marketplace godrose/bdd`.

The plugin namespaces its commands: `/bdd:discover`, `/bdd:design`, `/bdd:implement`, `/bdd:run`, `/bdd:triage` and `/bdd:reconcile`.

A plugin cannot create files in your project, so run `/bdd:init` once in each project. It copies the template to `.claude/bdd-config.md`. It never overwrites an existing config, and it does not fill in anything: the file still has placeholders. Claude Code may ask you to approve the copy, because it writes into `.claude/`. Open it and fill in the commands and paths for your project, as described under Configure, then commit it.

To get proposed values instead of filling the file in by hand, run `/bdd:init --detect`. It reads your build files, CI workflows, README and `.feature` files, and proposes a value for each placeholder row, with the file it came from and a confidence level. It writes only the rows you approve, never changes a row that already has a value, never runs your commands, and says `unknown` where the files do not answer. Check the commands it proposes before you rely on them. It also proposes your own skills for the `domain-knowledge` and `requirements-sync` roles, matched by the name and one-line description in `.claude/commands/` and `.claude/skills/`. If several fit, it names the runners-up, and if none fit, it leaves the row alone. It is plugin only.

`/bdd:init` also lists leftover project-file copies of the skills, which give duplicate commands next to the plugin. It only reports them and never deletes. Your own `bdd-*` skills are told apart from the installer's files by the `# Source:` line the installer writes.

<details>
<summary><b>As project files</b></summary>

Use this when you do not want a plugin, or when you want the skills committed in your repo.

```bash
# Remote install (no clone needed):
curl -sL https://raw.githubusercontent.com/godrose/bdd/main/install.sh | bash -s -- /path/to/your/project

# Or from a local clone:
git clone https://github.com/godrose/bdd.git /tmp/bdd-skills
/tmp/bdd-skills/install.sh /path/to/your/project
```

This copies the skills into `.claude/` with source headers (repo URL + commit hash) and creates `bdd-config.md` from the template. Commit the result. The repo is self-contained after install.

Project files have no plugin namespace, so the commands use a hyphen: `/bdd-discover`, `/bdd-design`, `/bdd-implement`, `/bdd-run`, `/bdd-triage` and `/bdd-reconcile`. Everything else in this README applies to both ways. Where it says `/bdd:design`, type `/bdd-design`.

</details>

<details>
<summary><b>Moving from project files to the plugin</b></summary>

1. Install the plugin as above.
2. Delete the files the installer created, and only these: `.claude/commands/bdd-discover.md`, `bdd-design.md`, `bdd-implement.md`, `bdd-run.md`, `bdd-triage.md` and `bdd-reconcile.md` in that folder, plus `.claude/agents/bdd-verifier.md`, `.claude/scripts/decisions.sh` and `.claude/schemas/decision.schema.json`. Some may not exist, because older installs did not have every file. That is fine. Having both sets gives you duplicate commands.
   Keep your own skills, such as `bdd-<project>-knowledge.md` or a sync skill. They are not part of the plugin.
3. Keep `.claude/bdd-config.md`. In its Skill Roles table, change `bdd-design` to `bdd:design`, and the same for the other skills and the verifier.
4. Tell the maintainer if you still need the project-file install. It stays for a few releases.

</details>

## Configure

Edit `.claude/bdd-config.md` in your project, or let `/bdd:init --detect` propose the values. Skills reference each other by **role** (from the Skill Roles table in that file), not by name, so you swap an implementation by editing the config.

<details>
<summary><b>Tooling rows by framework</b></summary>

Drop one of these row sets into the **Tooling** table (the template ships with the column headers already in place):

**Playwright-BDD (TypeScript):**
```markdown
| generate | `npx bddgen` |
| test | `npx playwright test` |
| typecheck | `npx tsc --noEmit --noUnusedLocals --noUnusedParameters` |
```

**SpecFlow (C#/.NET):**
```markdown
| generate | `dotnet build -c ServerWithFake` |
| test | `dotnet test -c ServerWithFake --no-build` |
| typecheck | `dotnet build -c ServerWithFake -warnaserror` |
```

**Cucumber (Java/Kotlin):**
```markdown
| generate | `mvn compile` |
| test | `mvn test -Dcucumber.filter.tags="@smoke"` |
| typecheck | `mvn compile -Werror` |
```

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
| `decision_log` | `off` | `on` records decisions in `decisions_dir` |
| `decisions_dir` | `docs/decisions` | Where the decision log lives |
| `scenario_id_prefix` | `spec-` | Prefix of the stable scenario id tag |
| `automated_tag` | none | Tag your test-management tool keys on, added when a scenario is automated |
| `glossary_file` | none | Domain terms for the vocabulary check |
| `lint` | none | Project linter for tags, casing and indentation |
| `prepare` | none | Command that builds what the tests launch, run before generate and test |
| `discovery_dir` | `docs/discovery` | Where a saved discovery pack goes |

</details>

<details>
<summary><b>Optional skills (project-specific)</b></summary>

These are NOT included. Create them in your project's `.claude/commands/`:

- **Domain knowledge** (`bdd-<project>-knowledge.md`): project-specific selectors, patterns, gotchas
- **Requirements sync** (`bdd-jira-sync.md`, `bdd-azdo-sync.md`, etc.): fetch ACs from issue tracker, publish results

Register them in `bdd-config.md` under Skill Roles.

</details>

## Decision log

Opt in with `decision_log` set to `on`. Each story gets a file, `docs/decisions/<story>.jsonl`, with one JSON record per line. A record says what was decided, why, which scenarios it adds, changes or removes, and links to where it was agreed (Slack, Jira, a pull request). Records are append-only. A change of mind is a new record that supersedes the old one. Git is the source of truth. Jira and your test-management tool only show it.

The log needs `jq`. Add `docs/decisions/*.jsonl merge=union` to `.gitattributes` so parallel branches can append to one file.

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
  plugin.json                   # Plugin manifest: name, version
  marketplace.json              # Marketplace listing for this repo
commands/
  init.md                       # Plugin only: create .claude/bdd-config.md from the template (copy only)
  discover.md                   # Discover what to build: questions, examples, edge cases, exclusions
  design.md                     # Design scenarios from ACs - analyze gaps, formulate, implement
  implement.md                  # Implement step definitions - explore UI, discover selectors, verify
  run.md                        # Run tests by tag/name/suite - config-driven, any framework
  triage.md                     # Turn pasted channel discussion into scenario edits and decision records
  reconcile.md                  # Report drift between the decision log and the scenarios
agents/
  verifier.md                   # Run tests + type check, report results (read-only, no edits)
scripts/decisions.sh            # Check, fingerprint, status and story page for the decision log (needs jq)
schemas/decision.schema.json    # Record schema read by decisions.sh
bdd-config.template.md          # Project config template - fill in your tooling and conventions
install.sh                      # Copy the skills into a project's .claude/ directory as bdd-<name> files
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
  │               └─ Dispatches: verifier agent (run tests + type check)
  └─ Discovers: requirements-sync skill (publish results, optional)

bdd:triage (optional: channel discussion to approved edits and decision records)
bdd:reconcile (optional: report drift between the decision log and the scenarios)
```

Skills reference each other by **role** (from `bdd-config.md`), not by name. The optional roles `reconciler` and `feedback-intake` point at `bdd:reconcile` and `bdd:triage`.

With the decision log on, `bdd:triage` turns channel discussion into approved edits and records, and `bdd:reconcile` reports drift (neither runs tests).

In `specify-only` mode, `bdd:design` stops after the scenarios. `bdd:implement` runs later, once they are approved.

</details>

## Update

**Plugin.** The plugin is cached by version, so you get changes when the version goes up:

```bash
claude plugin marketplace update godrose-plugins
claude plugin update bdd@godrose-plugins
```

Restart Claude Code to apply the update.

**Project files.** Re-run the install script. Your `bdd-config.md` won't be overwritten. The installer prints a note for each newer row your config lacks, with its default.

```bash
cd /tmp/bdd-skills && git pull
/tmp/bdd-skills/install.sh /path/to/your/project
```

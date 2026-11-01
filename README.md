# BDD Skills for Claude Code

BDD workflow skills for Claude Code: design scenarios from acceptance criteria, implement step definitions, and verify they pass. Framework-agnostic — works with Playwright-BDD, SpecFlow, Cucumber, or any Gherkin runner.

## The flow

For an individual builder:

1. `/bdd-discover <story>` asks one question at a time and finds examples, edge cases and exclusions. Trivial changes skip it.
2. `/bdd-design` shows the scenarios in plain words, with a reuse audit of every step. You approve them.
3. `/bdd-implement` automates the scenarios and `bdd-verifier` checks them.

The agreed scenarios become automated checks, so later changes cannot silently break them.

## Modes

The default mode is `specify-and-implement`. For teams there is `specify-only`: design and approve the scenarios, then stop. The scenarios are written as `.feature` files and tagged `@pending`, or `@manual-only` when a scenario stays manual by design. A product manager can review them in a pull request before any automation exists. Automate them later with `/bdd-implement`. `/bdd-run` and `bdd-verifier` skip scenarios tagged `@pending` or `@manual-only`, and undefined steps under those tags are never an error.

Choose the mode with the `workflow_mode` row in `.claude/bdd-config.md`, or per run with `--specify-only` or `--specify-and-implement`. If the row is absent, the default applies.

## What's included

```
.claude/
  commands/
    bdd-discover.md             # Discover what to build: questions, examples, edge cases, exclusions
    bdd-design.md               # Design scenarios from ACs — analyze gaps, formulate, implement
    bdd-implement.md            # Implement step definitions — explore UI, discover selectors, verify
    bdd-run.md                  # Run tests by tag/name/suite — config-driven, any framework
    bdd-feedback.md             # Turn pasted channel discussion into scenario edits and decision records
    bdd-reconcile.md            # Report drift between the decision log and the scenarios
  agents/
    bdd-verifier.md             # Run tests + type check, report results (read-only, no edits)
  scripts/decisions.sh          # Check, fingerprint, status and story page for the decision log (needs jq)
  schemas/decision.schema.json  # Record schema read by decisions.sh
  bdd-config.template.md        # Project config template — fill in your tooling and conventions
install.sh                      # Copy skills into your project's .claude/ directory
```

## Architecture

```
bdd-discover (optional first step: questions, examples, edge cases)
  └─ hands a discovery pack to:
bdd-design (methodology: what scenarios to create)
  ├─ Discovers: requirements-sync skill (fetch ACs, optional)
  ├─ Invokes:   implementer skill (implement each scenario)
  │               ├─ Discovers: domain-knowledge skill (project patterns, optional)
  │               └─ Dispatches: verifier agent (run tests + type check)
  └─ Discovers: requirements-sync skill (publish results, optional)

bdd-feedback (optional: channel discussion to approved edits and decision records)
bdd-reconcile (optional: report drift between the decision log and the scenarios)
```

Skills reference each other by **role** (from `bdd-config.md`), not by name. Swap implementations by editing the config. The optional roles `reconciler` and `feedback-intake` point at `bdd-reconcile` and `bdd-feedback`.

With the decision log on, `bdd-feedback` turns channel discussion into approved edits and records, and `bdd-reconcile` reports drift (neither runs tests).

In `specify-only` mode, `bdd-design` stops after the scenarios. `bdd-implement` runs later, once they are approved.

## Install

```bash
# Remote install (no clone needed):
curl -sL https://raw.githubusercontent.com/godrose/bdd/main/install.sh | bash -s -- /path/to/your/project

# Or from a local clone:
git clone https://github.com/godrose/bdd.git /tmp/bdd-skills
/tmp/bdd-skills/install.sh /path/to/your/project
```

This copies skills into `.claude/` with source headers (repo URL + commit hash) and creates `bdd-config.md` from the template. Commit the result — the repo is self-contained after install.

## Configure

Edit `.claude/bdd-config.md` in your project. Drop one of these row sets into the **Tooling** table (the template ships with the column headers already in place):

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

## Decision log (opt-in)

Set `decision_log` to `on` to keep a decision log. Each story gets a file, `docs/decisions/<story>.jsonl`, with one JSON record per line. A record says what was decided, why, which scenarios it adds, changes or removes, and links to where it was agreed (Slack, Jira, a pull request). Records are append-only. A change of mind is a new record that supersedes the old one. Git is the source of truth. Jira and your test-management tool only show it.

The log needs `jq`. Add `docs/decisions/*.jsonl merge=union` to `.gitattributes` so parallel branches can append to one file.

Each scenario in the log carries a stable tag such as `@spec-export-empty-list`. Scenarios without one are legacy and not tracked. They get an id the first time a decision touches them.

### Feedback intake

Each story has one channel for discussion. Paste that text into `/bdd-feedback <story>`. The skill classifies each message as approve, change, question or unclear, proposes scenario edits and records, and writes nothing until you approve each item. Unclear never counts as approval.

### Reconcile

`/bdd-reconcile` runs `decisions.sh check` and reports orphans, drift, undecided scenarios and conflicts. It is a report, not a sync, and it never edits anything. The same check can run in CI or a pre-push hook.

### Story page

`decisions.sh show <story>` prints a read-only story page in Markdown for product managers: what was agreed (with a status: automated, planned, checked by hand or waiting on the product), what was left out or postponed, what is still open, and the history. With `--since <ref>` it lists what changed since you last looked. Paste it into Jira, Confluence or Slack.

## Optional config rows

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
| `discovery_dir` | `docs/discovery` | Where a saved discovery pack goes |

## Optional skills (project-specific)

These are NOT included — create them in your project's `.claude/commands/`:

- **Domain knowledge** (`bdd-<project>-knowledge.md`) — project-specific selectors, patterns, gotchas
- **Requirements sync** (`bdd-jira-sync.md`, `bdd-azdo-sync.md`, etc.) — fetch ACs from issue tracker, publish results

Register them in `bdd-config.md` under Skill Roles.

## Update

Re-run the install script to update skills. Your `bdd-config.md` won't be overwritten. The installer prints a note for each newer row your config lacks, with its default.

```bash
cd /tmp/bdd-skills && git pull
/tmp/bdd-skills/install.sh /path/to/your/project
```

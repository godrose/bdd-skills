# BDD Skills for Claude Code

BDD workflow skills for Claude Code: design scenarios from acceptance criteria, implement step definitions, and verify they pass. Framework-agnostic — works with Playwright-BDD, SpecFlow, Cucumber, or any Gherkin runner.

## The flow

For an individual builder:

1. `/bdd-discover <story>` asks one question at a time and finds examples, edge cases and exclusions. Trivial changes skip it.
2. `/bdd-design` shows the scenarios in plain words, with a reuse audit of every step. You approve them.
3. `/bdd-implement` automates the scenarios and `bdd-verifier` checks them.

The agreed scenarios become automated checks, so later changes cannot silently break them.

## Modes

The default mode is `specify-and-implement`. For teams there is `specify-only`: design and approve the scenarios, then stop. The scenarios are written as `.feature` files and tagged `@manual`. A product manager can review them in a pull request before any automation exists. Automate them later with `/bdd-implement`.

Choose the mode with the `workflow_mode` row in `.claude/bdd-config.md`, or per run with `--specify-only` or `--specify-and-implement`. If the row is absent, the default applies.

## What's included

```
.claude/
  commands/
    bdd-discover.md             # Discover what to build: questions, examples, edge cases, exclusions
    bdd-design.md               # Design scenarios from ACs — analyze gaps, formulate, implement
    bdd-implement.md            # Implement step definitions — explore UI, discover selectors, verify
    bdd-run.md                  # Run tests by tag/name/suite — config-driven, any framework
  agents/
    bdd-verifier.md             # Run tests + type check, report results (read-only, no edits)
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
```

Skills reference each other by **role** (from `bdd-config.md`), not by name. Swap implementations by editing the config.

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

## Optional config rows

Every row below is optional. If a row is absent, the default applies.

| Row | Default | Purpose |
|-----|---------|---------|
| `workflow_mode` | `specify-and-implement` | `specify-only` stops after the approved scenarios |
| `unautomated_tag` | `@manual` | Tag for scenarios written but not yet automated |
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

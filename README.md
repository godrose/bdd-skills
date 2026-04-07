# BDD Skills for Claude Code

Generic BDD workflow skills for Claude Code. Framework-agnostic — works with Playwright-BDD, SpecFlow, Cucumber, or any Gherkin-based test framework.

## What's included

```
.claude/
  commands/
    bdd-scenario-design.md      # Design scenarios from ACs — analyze gaps, formulate, implement
    bdd-implement-scenario.md   # Implement step definitions — explore UI, discover selectors, verify
  agents/
    bdd-verifier.md             # Run tests + type check, report results (read-only, no edits)
  bdd-config.template.md        # Project config template — fill in your tooling and conventions
install.sh                      # Copy skills into your project's .claude/ directory
```

## Architecture

```
bdd-scenario-design (methodology — what scenarios to create)
  ├─ Discovers: requirements-sync skill (fetch ACs, optional)
  ├─ Invokes:   implementer skill (implement each scenario)
  │               ├─ Discovers: domain-knowledge skill (project patterns, optional)
  │               └─ Dispatches: verifier agent (run tests + type check)
  └─ Discovers: requirements-sync skill (publish results, optional)
```

Skills reference each other by **role** (from `bdd-config.md`), not by name. Swap implementations by editing the config.

## Install

```bash
# Clone and install into your project
git clone https://github.com/godrose/bdd.git /tmp/bdd-skills
/tmp/bdd-skills/install.sh /path/to/your/project

# Or from within your project root
/path/to/bdd-skills/install.sh .
```

This copies skills into `.claude/` and creates `bdd-config.md` from the template.

## Configure

Edit `.claude/bdd-config.md` in your project with your specific tooling:

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

## Optional skills (project-specific)

These are NOT included — create them in your project's `.claude/commands/`:

- **Domain knowledge** (`bdd-<project>-knowledge.md`) — project-specific selectors, patterns, gotchas
- **Requirements sync** (`bdd-jira-sync.md`, `bdd-azdo-sync.md`, etc.) — fetch ACs from issue tracker, publish results

Register them in `bdd-config.md` under Skill Roles.

## Update

Re-run the install script to update skills. Your `bdd-config.md` won't be overwritten.

```bash
cd /tmp/bdd-skills && git pull
/tmp/bdd-skills/install.sh /path/to/your/project
```

## Tested with

- [godrose/bdd-netcore](https://github.com/godrose/bdd-netcore) — SpecFlow + xUnit + .NET 6 (7 scenarios)

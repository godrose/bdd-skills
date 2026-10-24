# BDD Project Configuration

Project-level manifest mapping roles to tools, conventions, and skills. Read by all BDD skills/agents at runtime to avoid hardcoded references.

## Tooling

| Role | Command |
|------|---------|
| generate | `<command to generate test files from .feature files>` |
| test | `<command to run tests>` |
| typecheck | `<command to check types / compile with strict warnings>` |
| show-trace | `<command to view test traces, if available>` |
| lint | `<optional project linter for tags, casing, indentation; empty to skip>` |

## Conventions

| Convention | Value |
|-----------|-------|
| features_dir | `<path to .feature files>` |
| steps_dir | `<path to step definitions>` |
| config_file | `<path to test framework config>` |
| test_results_dir | `<path to test output artifacts>` |
| error_context | `<path pattern for failure context, or empty if using stdout>` |
| state_type | `<type name for shared test state>` |
| state_fixture | `<fixture/variable name for shared state>` |
| glossary_file | `<optional path to a domain glossary; empty to skip>` |
| discovery_dir | `docs/discovery` (where a saved discovery pack goes; optional) |
| unautomated_tag | `@manual` (tag for scenarios written but not yet automated; optional) |
| automated_tag | `<optional tag your test-management tool keys on, e.g. @automated; empty to skip>` |

## Workflow

| Setting | Value |
|---------|-------|
| workflow_mode | `specify-and-implement` (default) or `specify-only` (stop at the scenarios, automate later) |

## Skill Roles

| Role | Skill/Agent | Required | Description |
|------|-------------|----------|-------------|
| discoverer | `bdd-discover` | no | Turn a story into questions, examples and edge cases before design |
| designer | `bdd-design` | yes | Formulate scenarios from ACs |
| implementer | `bdd-implement` | yes | Implement step definitions |
| verifier | `bdd-verifier` (agent) | yes | Run tests + type check, report results |
| test-runner | `bdd-run` | no | Environment selection + test execution |
| domain-knowledge | `<your-project-knowledge-skill>` | no | Project-specific selectors and patterns |
| requirements-sync | `<your-sync-skill>` | no | Fetch ACs from issue tracker, publish results |

## Code Quality

| Rule | Details |
|------|---------|
| Typecheck must pass | Run **typecheck** command — zero errors required |
| No unused code | Remove unused imports, locals, parameters; prefix intentional unused with `_` |
| State properties declared | New properties on **state_fixture** must be added to **state_type** |
| Dead code | Delete entirely, don't comment out |

# BDD Project Configuration

Project-level manifest mapping roles to tools, conventions, and skills. Read by all BDD skills/agents at runtime to avoid hardcoded references.

## Tooling

| Role | Command |
|------|---------|
| prepare | `` (optional command that builds what the tests launch, such as servers; runs before generate and test; empty to skip) |
| generate | `_(not needed: cucumber-js reads .feature files directly)_` |
| test | `npm run scenarios` |
| typecheck | `npx tsc --noEmit --noUnusedLocals --noUnusedParameters` |
| show-trace | `<command to view test traces, if available>` |
| lint | `<optional project linter for tags, casing, indentation; empty to skip>` |

## Conventions

| Convention | Value |
|-----------|-------|
| features_dir | `specs/features` |
| steps_dir | `specs/steps` |
| config_file | `cucumber.js` |
| test_results_dir | `<path to test output artifacts>` |
| error_context | `<path pattern for failure context, or empty if using stdout>` |
| state_type | `World` |
| state_fixture | `this` |
| glossary_file | `<optional path to a domain glossary; empty to skip>` |
| discovery_dir | `docs/discovery` (where a saved discovery pack goes; optional) |
| out_of_scope_file | `docs/out-of-scope.md` (where exclusions and removals are listed; optional) |
| unautomated_tag | `@pending` (tag for scenarios planned to be automated; optional) |
| automated_tag | `<optional tag your test-management tool keys on, e.g. @automated; empty to skip>` |
| decisions_dir | `docs/decisions` (where the decision log lives; used when decision_log is on) |
| scenario_id_prefix | `spec-` (stable scenario id tag prefix, for example `@spec-export-empty-list`) |
| status_scope | `scenario` (where the planned marker sits: `scenario`, `feature` or `directory`) |
| manual_only_tag | `@manual-only` (scenarios that stay manual by design; never automated) |
| blocked_tag | `` (optional tag for scenarios waiting on the product; empty to skip) |
| planned_dir | `` (with directory scope: a path component that marks planned scenarios) |
| manual_only_dir | `` (with directory scope: a path component that marks manual-only scenarios) |

## Workflow

| Setting | Value |
|---------|-------|
| workflow_mode | `specify-and-implement` (default) or `specify-only` (stop at the scenarios, automate later) |
| decision_log | `off` (default) or `on` (record decisions in `decisions_dir`) |
| step_batch | `` (optional: `auto` groups steps by risk in `implement`; `1`, a number or `all` fixes the steps per run; empty means `auto`) |

## Skill Roles

| Role | Skill/Agent | Required | Description |
|------|-------------|----------|-------------|
| discoverer | `bdd:discover` | no | Turn a story into questions, examples and edge cases before design |
| designer | `bdd:design` | yes | Formulate scenarios from ACs |
| reconciler | `bdd:reconcile` | no | Report drift between the decision log and the scenarios |
| feedback-intake | `bdd:triage` | no | Turn pasted channel discussion into scenario edits and decision records |
| implementer | `bdd:implement` | yes | Implement step definitions |
| verifier | `bdd:verifier` (agent) | yes | Run tests + type check, report results |
| test-runner | `bdd:run` | no | Environment selection + test execution |
| domain-knowledge | `<your-project-knowledge-skill>` | no | Project-specific selectors and patterns |
| requirements-sync | `<your-sync-skill>` | no | Fetch ACs from issue tracker, publish results |

## Code Quality

| Rule | Details |
|------|---------|
| Typecheck must pass | Run **typecheck** command - zero errors required |
| No unused code | Remove unused imports, locals, parameters; prefix intentional unused with `_` |
| State properties declared | New properties on **state_fixture** must be added to **state_type** |
| Dead code | Delete entirely, don't comment out |

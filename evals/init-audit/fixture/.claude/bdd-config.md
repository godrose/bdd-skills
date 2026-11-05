# BDD Project Configuration

## Tooling

| Role | Command |
|------|---------|
| prepare | `` |
| generate | `_(not needed: the framework reads .feature files directly)_` |
| test | `npm test` |
| typecheck | `npx tsc --noEmit` |

## Conventions

| Convention | Value |
|-----------|-------|
| features_dir | `features` |
| steps_dir | `src/step-defs` |
| config_file | `playwright.config.ts` |
| unautomated_tag | `@pending` |
| decisions_dir | `docs/decisions` |

## Workflow

| Setting | Value |
|---------|-------|
| workflow_mode | `specify-and-implement` |
| decision_log | `on` |

## Skill Roles

| Role | Skill/Agent | Required | Description |
|------|-------------|----------|-------------|
| designer | `bdd:design` | yes | Formulate scenarios from ACs |
| implementer | `bdd:implement` | yes | Implement step definitions |

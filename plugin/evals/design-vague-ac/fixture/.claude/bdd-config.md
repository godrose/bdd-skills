# BDD Project Configuration

## Tooling

| Role | Command |
|------|---------|
| generate | `npx bddgen` |
| test | `npx playwright test` |

## Conventions

| Convention | Value |
|-----------|-------|
| features_dir | `features` |
| steps_dir | `steps` |
| config_file | `playwright.config.ts` |
| unautomated_tag | `@pending` |
| scenario_id_prefix | `spec-` |

## Workflow

| Setting | Value |
|---------|-------|
| workflow_mode | `specify-only` |
| decision_log | `off` |

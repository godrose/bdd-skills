# BDD Project Configuration

## Tooling

| Role | Command |
|------|---------|
| prepare | `` |
| generate | `_(not needed: the framework reads .feature files directly)_` |
| test | `sh ./fake-test.sh` |

## Conventions

| Convention | Value |
|-----------|-------|
| features_dir | `features` |
| steps_dir | `steps` |
| config_file | `playwright.config.ts` |
| unautomated_tag | `@pending` |

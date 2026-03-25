---
description: "Run BDD feature tests — select environment, scenarios by tag/name/suite, inspect results"
allowed-tools: ["Agent", "Bash", "Read", "Write", "Grep", "Glob", "AskUserQuestion"]
---

## Test Feature — Run BDD Scenarios

Generic workflow for running Playwright-BDD feature tests against any configured environment.

### Input

The user provides one or more of:
- A suite tag (e.g., `@smoke`, `@deep`, `@E2E`)
- An individual scenario tag (e.g., `@login`, `@analytics`)
- A scenario name or partial match (e.g., "pipeline sanity", "schema")
- A feature file path
- "all" to run everything

### Step 1: Environment Selection

**Ask the user which environment to run against** (unless already specified).

Read `support/env.ts` for available environments and their config. Default to `playground` if the user doesn't specify.

### Step 2: Discover Available Scenarios

If the user's intent is ambiguous, scan for available scenarios:

```bash
grep -r "Scenario\|Scenario Outline" features/ --include="*.feature"
```

For tag discovery:
```bash
grep -r "^[[:space:]]*@" features/ --include="*.feature" | sort -u
```

### Step 3: Project Auto-Detection

Read `playwright.config.ts` to discover available projects. Map the user's scenario to the correct project:
- Check which feature file contains the scenario
- Match feature file to project based on config (test directory patterns, grep filters, etc.)
- If unclear, default to `--project e2e`

### Step 4: Prerequisites

Before running, verify:

1. **Auth state**: `.auth/<env>.json` exists — run `TEST_ENV=<env> npx tsx scripts/setup-auth.ts` if missing
2. **Dependencies**: `node_modules` exists — run `npm install` if missing
3. **Code generation**: `npx bddgen` runs cleanly
4. **Environment-specific prereqs**: Check if the feature's Background or preconditions require special setup (e.g., AWS SSO login, VPN, external tools)

### Step 5: Run Tests

**By tag:**
```bash
TEST_ENV=<env> npx playwright test --grep "<tag>" --project <project>
```

**By scenario name (partial match, case-insensitive):**
```bash
TEST_ENV=<env> npx playwright test --grep "<partial name>" --project <project>
```

**Multiple scenarios (regex OR):**
```bash
TEST_ENV=<env> npx playwright test --grep "<tag1>|<tag2>" --project <project>
```

**Single feature file:**
```bash
TEST_ENV=<env> npx playwright test <path-to-feature> --project <project>
```

### Step 6: Results

**Always open the report after a test run:**
```bash
open reports/bdd-report/index.html
```

**On failure, inspect artifacts in `test-results/<test-name>/`:**
- `error-context.md` — accessibility snapshot at failure point
- `video.webm` — browser recording
- `trace.zip` — open with `npx playwright show-trace <path>`
- `attachments/` — screen recordings, screenshots, evidence files

**Report the outcome:**
- Which scenarios passed/failed
- For failures: the step that failed, the error message, and what the accessibility snapshot shows
- Suggest next steps (re-run with `--headed` for debugging, invoke `bdd-implement-scenario` to fix)

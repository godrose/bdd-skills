---
description: "Implement a BDD scenario step by step — explore UI, discover selectors, implement steps, verify iteratively"
allowed-tools: ["Agent", "Bash", "Read", "Write", "Edit", "Grep", "Glob"]
---

## BDD Implement Scenario

Implement a Playwright-BDD scenario by exploring the actual UI state at each step, discovering correct selectors, and verifying iteratively.

This is a **generic workflow** that works with any Playwright-BDD project. Project-specific patterns and selector knowledge are loaded separately.

### Input

The user provides a `.feature` file path or scenario name. Parse the scenario to get the ordered list of Given/When/Then steps.

### Workflow

#### Phase 0: Understand the Scenario

1. Read the `.feature` file to get the full scenario with all steps
2. Read existing step definitions in `steps/` to see which steps are already implemented
3. Read relevant Page Object Models to understand current selectors
4. Read environment config for target URLs and auth
5. Identify which steps need new implementation vs which already exist

#### Phase 1: Prepare

1. Ensure `npx bddgen` runs cleanly
2. Check auth state exists (run auth setup script if missing)
3. Identify the correct Playwright project from `playwright.config.ts`

#### Phase 2: Step-by-Step Implementation

For each step in the scenario, IN ORDER:

##### 2a. Run the test

```bash
npx bddgen && npx playwright test --project=<project> --grep "<scenario-tag>" --headed 2>&1
```

If the step passes → move to the next step.
If the step fails → go to 2b.

##### 2b. Explore the UI at the failure point

**Read the error context file** at `test-results/<test-name>/error-context.md`. This contains a YAML accessibility snapshot of the page at the moment of failure.

**Key rules for selector discovery:**
- Use the accessibility snapshot, NOT guesswork
- Look for `button`, `link`, `tab`, `heading`, `textbox` roles with their actual names
- Check for `data-testid` attributes first — most reliable
- Note the element hierarchy — scoping selectors to parent containers prevents false matches
- Use `.first()` on locators that may match multiple elements
- For component library dropdowns (MUI, Ant, etc.), prefer element IDs over role-based selectors to avoid strict mode violations

**Before fixing**, check if the project has a domain knowledge skill (e.g., `bdd-<project>-knowledge`). Invoke it to avoid known selector pitfalls.

##### 2c. Fix the implementation

Based on what you learned from the UI state:
1. Update the Page Object Model
2. Update step definitions
3. Update support modules if needed

##### 2d. Verify the fix

Re-run the test. If the step now passes, move to the next step. If not, repeat 2b-2d.

**Max retries per step: 3.** If a step fails 3 times, stop and report what you've learned from the accessibility snapshots. The user may need to provide guidance.

#### Phase 3: Full Scenario Verification

Once all steps pass individually, run the full scenario end-to-end (without `--headed`):

```bash
npx bddgen && npx playwright test --project=<project> --grep "<scenario-tag>" 2>&1
```

After failure, inspect available artifacts:
- `test-results/<test-name>/video.webm` — browser recording
- `test-results/<test-name>/trace.zip` — open with `npx playwright show-trace <path>`
- `test-results/<test-name>/error-context.md` — accessibility snapshot at failure
- Any screen recordings in `test-results/<test-name>/attachments/`

---

### Playwright-BDD Conventions

These apply to ALL Playwright-BDD projects:

| Pattern | Wrong | Right |
|---------|-------|-------|
| Share state between steps | `this` context | `testState` fixture (mutable object) |
| Extend test base | Import from `@playwright/test` | Import from `playwright-bdd` |
| Attach evidence | Direct in step | `$testInfo.attach()` fixture |
| Step parameter types | Hardcoded strings | Use Cucumber expressions (`{string}`, `{int}`, `{float}`) |
| Background steps | Re-run expensive setup | Cache results in `testState`, detect already-done state |

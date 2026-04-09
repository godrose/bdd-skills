---
description: "Implement a BDD scenario step by step — explore UI, discover selectors, implement steps, verify iteratively"
allowed-tools: ["Agent", "Bash", "Read", "Write", "Edit", "Grep", "Glob"]
---

## BDD Implement Scenario

Implement a BDD scenario by exploring the actual UI state at each step, discovering correct selectors, and verifying iteratively.

This skill handles **execution only** — it takes a scenario (from a `.feature` file or from the **designer** skill) and implements the step definitions, POMs, and support code needed to make it pass.

**Before starting**, read `.claude/bdd-config.md` for project-specific tooling, conventions, and skill role mappings. Project-specific patterns and selector knowledge are loaded separately via the **domain-knowledge** skill if configured.

### Input

A `.feature` file path or scenario tag. The scenario Gherkin must already exist in a `.feature` file.

### Workflow

#### Phase 0: Understand the Scenario

1. Read the `.feature` file to get the full scenario with all steps
2. Read existing step definitions in the **steps_dir** to see which steps are already implemented
3. Read relevant Page Object Models to understand current selectors
4. Read environment config for target URLs and auth
5. Identify which steps need new implementation vs which already exist

#### Phase 1: Prepare

1. Ensure the **generate** command runs cleanly
2. Check auth state exists (run auth setup script if missing)
3. Identify the correct project from the **config_file** (tag-based routing)

#### Phase 2: Step-by-Step Implementation

For each step in the scenario, IN ORDER:

##### 2a. Run the test

Run the **generate** command followed by the **test** command with the appropriate project and scenario tag flags, plus `--headed` for visual debugging.

If the step passes -> move to the next step.
If the step fails -> go to 2b.

##### 2b. Explore the failure point

Gather failure details using the best available source (in priority order):

1. **Error context file** — if **error_context** is configured in BDD config, read it. For UI frameworks this typically contains an accessibility snapshot of the page at failure time.
2. **Test results directory** — check **test_results_dir** for artifacts (screenshots, traces, logs).
3. **Test runner stdout** — parse the failure stack trace, assertion message, and step name.

**For UI-based tests — key rules for selector discovery:**
- Use the accessibility snapshot or page source, NOT guesswork
- Look for `button`, `link`, `tab`, `heading`, `textbox` roles with their actual names
- Check for `data-testid` attributes first — most reliable
- Note the element hierarchy — scoping selectors to parent containers prevents false matches
- Use `.first()` on locators that may match multiple elements
- For component library dropdowns (MUI, Ant, etc.), prefer element IDs over role-based selectors to avoid strict mode violations

**Before fixing**, check if a **domain-knowledge** skill is configured in the BDD config. Invoke it to avoid known pitfalls.

##### 2c. Fix the implementation

Based on what you learned from the UI state:
1. Update the Page Object Model
2. Update step definitions
3. Update support modules if needed

##### 2d. Verify the fix

Re-run the test. If the step now passes, move to the next step. If not, repeat 2b-2d.

**Max retries per step: 3.** If a step fails 3 times, stop and report what you've learned from the accessibility snapshots. The user may need to provide guidance.

#### Phase 3: Full Scenario Verification

Once all steps pass individually, dispatch the **verifier** agent (from BDD config) for end-to-end verification:

```
Scope: strict
Project: <project>
Tag: <scenario-tag>
```

The verifier runs the full scenario (without `--headed`) and the strict type check. If it reports failures, fix and re-dispatch.

If dispatching the agent is not possible, run manually: the **generate** command, then the **test** command, then the **typecheck** command (all from BDD config). All must pass with zero errors before the scenario is considered complete.

After failure, inspect available artifacts in the **test_results_dir**:
- `error-context.md` — accessibility snapshot at failure
- `video.webm` — browser recording
- `trace.zip` — open with the **show-trace** command

---

### BDD Conventions

| Pattern | Wrong | Right |
|---------|-------|-------|
| Share state between steps | `this` context | **state_fixture** (mutable object, see BDD config) |
| Extend test base | Import from test framework | Import from BDD framework wrapper |
| Attach evidence | Direct in step | `$testInfo.attach()` fixture |
| Step parameter types | Hardcoded strings | Use Cucumber expressions (`{string}`, `{int}`, `{float}`) |
| Background steps | Re-run expensive setup | Cache results in state fixture, detect already-done state |

### Code Quality Rules

Read from `.claude/bdd-config.md` — the config is the single source of truth for quality rules. Key principles:

- **Typecheck must pass** with zero errors (run the **typecheck** command)
- **No unused code** — imports, locals, parameters, dead methods
- **State properties declared** — new properties on the state fixture must be added to the state type
- **Dynamic imports** — use `.js` extension for node16 moduleResolution
- **No `as any`** for properties that should be typed

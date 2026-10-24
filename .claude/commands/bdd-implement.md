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

The scenarios may come from an approved spec: a `specify-only` run of the designer that left them unautomated and tagged with the project's unautomated tag.

### Workflow

#### Phase 0: Understand the Scenario

If a spec PR summary exists for an approved spec, read its **Step status** table first. Look for it beside the feature file as `<feature>.spec-summary.md`. If it is not there, ask for it. Treat the "new (to be built)" and "existing (not yet automated)" rows as the work list. Stop and report if an "existing (automated)" step can no longer be found, or if the wording of a new step differs from the approved scenario text. Do not reword approved scenarios silently.

1. Read the `.feature` file to get the full scenario with all steps
2. Read existing step definitions in the **steps_dir** to see which steps are already implemented
3. Read relevant Page Object Models to understand current selectors
4. Read environment config for target URLs and auth
5. Identify which steps need new implementation vs which already exist. For EACH apparently-new step, also run a paraphrase grep against the **steps_dir** — generate 2–3 natural paraphrases of the same assertion and search for each. If any paraphrase hits an existing step def, **stop and report back**: the `.feature` should be reworded to use the existing step text, not a new step def created. Do not author a duplicate step def silently — paraphrase blindness at implementation time is the last line of defense before a duplicate ships.

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
- **Escape regex specials when interpolating dynamic values into regex-based locators** — when a name-matching locator is built from a regex whose pattern was interpolated from an upstream value (an auto-discovered label, a file path, a formatted display string), characters like `(`, `)`, `.`, `[`, `]`, `?`, `+`, `*`, `|`, `\`, `^`, `$`, `{`, `}` are silently interpreted by the regex engine. The locator returns "no matches" even though the visible text matches the human's mental model exactly. Pipe the interpolated value through a regex-escape helper before constructing the regex. The smell that points at this bug: a snapshot-confirmed visible element that the locator still can't find

**Before fixing**, check if a **domain-knowledge** skill is configured in the BDD config. Invoke it to avoid known pitfalls.

##### 2c. Fix the implementation

Based on what you learned from the UI state:
1. Update the Page Object Model
2. Update step definitions
3. Update support modules if needed

**Before authoring a NEW step def** (as opposed to editing an existing one), repeat the paraphrase grep from Phase 0 step 5 against the current inventory. The inventory may have changed since Phase 0 (e.g., a sibling scenario was implemented in between, or a step def merged upstream). If a paraphrase now exists, reword the `.feature` instead of adding a duplicate.

**Import discipline** — author imports just-in-time for what the current edit actually references. Do NOT pre-import symbols you "might use" later, and do NOT carry over imports from a prior draft that the final step body no longer references. Unused imports become typecheck failures under `--noUnusedLocals` (or equivalent strict mode) and require a follow-up cleanup PR. Before exiting Phase 2c, scan the file for imports introduced in this iteration and confirm each one is referenced by the code you just wrote.

##### 2d. Verify the fix

Re-run the test. If the step now passes, move to the next step. If not, repeat 2b-2d.

**Max retries per step: 3.** If a step fails 3 times, stop and report what you've learned from the accessibility snapshots. The user may need to provide guidance.

#### Phase 3: Full Scenario Verification

After the verifier reports PASS for a scenario from an approved spec, remove the unautomated tag (the **unautomated_tag** row, default `@manual`) from it. If an **automated_tag** is configured, add it. Do this only after the verifier step below has passed.

Once all steps pass individually, dispatch the **verifier** agent (from BDD config) for end-to-end verification:

```
Scope: strict
Project: <project>
Tag: <scenario-tag>
```

The verifier runs the full scenario (without `--headed`) and the strict type check. Failures must be resolved before declaring the scenario done — re-dispatch after each fix.

If dispatching the agent is not possible, run manually: the **generate** command, then the **test** command, then the **typecheck** command (all from BDD config). All must pass with zero errors before the scenario is considered complete.

**Common typecheck failures and how to resolve them:**
- **Unused import / local / parameter** (e.g., `TS6133 declared but never read` in TypeScript projects) — delete the offending line. Use the `_`-prefix convention ONLY when an unused function parameter must remain to satisfy an interface or callback signature; never to silence an unused top-level import.
- **Missing import** (e.g., `cannot find name`) — add the import; verify the resolved path matches the project's module resolution config.
- **State-fixture property errors** — declare the new property on the **state_type** per Code Quality Rules below; don't paper over with `as any`.

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

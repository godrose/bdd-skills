---
description: "Implement a BDD scenario step by step - explore the system under test, implement steps, verify iteratively"
---

## BDD Implement Scenario

Implement a BDD scenario by exploring the actual state of the system under test at each step, finding the correct locators or calls, and verifying iteratively.

This skill takes a scenario (from a `.feature` file or from the **designer** skill) and makes it pass. It implements the step definitions, page objects or helpers, and support code. When the step code is right and the scenario still fails because the application does not do what it says, it builds the feature in the application too.

**Before starting**, read `.claude/bdd-config.md` for project-specific tooling, conventions, and skill role mappings. Project-specific patterns and selector knowledge are loaded separately via the **domain-knowledge** skill if configured. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

**UI rules.** The UI-specific rules below apply when the config sets **error_context** or **show-trace** (`/bdd:init --detect` fills them from the project). With neither set there is no UI evidence: use the neutral rules and say so in one line.

### Input

A `.feature` file path or scenario tag. The scenario Gherkin must already exist in a `.feature` file.

The scenarios may come from an approved spec: a `specify-only` run of the designer that left them unautomated and tagged with the project's unautomated tag.

Work on scenarios that carry the planned marker. Never edit or implement a scenario carrying the **manual_only_tag**: report that it stays manual.

### Workflow

#### Phase 0: Understand the Scenario

If a spec PR summary exists for an approved spec, read its **Step status** table first. Look for it beside the feature file as `<feature>.spec-summary.md`. If it is not there, ask for it. Treat the "new (to be built)" and "existing (not yet automated)" rows as the work list. Stop and report if an "existing (automated)" step can no longer be found, or if the wording of a new step differs from the approved scenario text. Do not reword approved scenarios silently.

1. Read the `.feature` file to get the full scenario with all steps
2. Read existing step definitions in every folder of the **steps_dir** (one path, or several comma-separated) to see which steps are already implemented
3. Read the page objects or helpers the steps use to understand current selectors or calls
4. Read environment config for target URLs and auth
5. Identify which steps need new implementation vs which already exist. For EACH apparently-new step, also run a paraphrase grep against the **steps_dir** - generate 2–3 natural paraphrases of the same assertion and search for each. If any paraphrase hits an existing step def, **stop and report back**: the `.feature` should be reworded to use the existing step text, not a new step def created. Do not author a duplicate step def silently - paraphrase blindness at implementation time is the last line of defense before a duplicate ships.
   If a reused `Then` step later fails because its assertion does not fit the scenario's data, stop and report the mismatch. Do not edit approved scenario data and do not reword the step.

#### Phase 1: Prepare

1. Run the **prepare** command from BDD config. If the row is absent, empty, still in `<...>` form, or a note such as `_(not needed)_`, skip this step and say so. If **prepare** fails, report the error and stop. Do not run generate or test.
2. Ensure the **generate** command runs cleanly
3. Check auth state exists (run auth setup script if missing)
4. Identify the correct project from the **config_file** (tag-based routing)

#### Phase 2: Step-by-Step Implementation

For each group, in order (a group is one step when **step_batch** is `1`):

##### 2.0. Plan the groups

Read the **step_batch** row. If the row is absent, empty or in `<...>` form, use `auto`. A value other than `auto`, `all` or a number is treated as `auto`, with a one-line note.

- `1`: one new step per run. A number `N`: N new steps per run. `all`: every new step, then one run. These are fixed: do no analysis.
- `auto`: classify each step before the first run, from what you read in Phase 0.
  - **existing**: a step definition already exists, or the Step status table says so. List it as "existing, no work". It needs no run.
  - **low**: a new step you can write by reading the repo. It composes or wraps page objects, helpers, client calls, endpoints, fixtures or locators whose definitions are readable in the source.
  - **high**: a new step that needs knowledge you cannot get by reading the repo: the state of a rendered page at that point, a value produced at run time, a response shape or formatted value the source does not define, or a locator the source does not determine (generated ids, third-party components). If unsure, classify it high. The keyword (Given, When, Then) is a tie-breaker only.

Form groups in order. Low steps accumulate. A high step closes the group. The plan does not wait for approval. In your final report, add a **Groups** section: for each group, its steps with their class and reason, the number of test runs, and the outcome.

##### 2a. Run the test

Run the **prepare** command, then the **generate** command, then the **test** command with the appropriate project and scenario tag flags, plus the project's visual-debug flag if the test command has one (UI projects).

If the group passes (at least one executed test, and none failed) -> move to the next group. If no tests ran, stop and report "no tests ran". Do not loop.
If the group fails -> go to 2b.

**Natural red.** Look at the first run of the scenario, before any step code is written for it. If a step fails on its assertion with an expected-versus-actual message, keep the step name and a short form of that message. It is the natural red for the red-first check in Phase 2.5. A run that reports only undefined steps is not a natural red.

##### 2b. Explore the failure point

Gather failure details using the best available source (in priority order):

1. **Error context file** - if **error_context** is configured in BDD config, read it. For UI frameworks this typically contains an accessibility snapshot of the page at failure time.
2. **Test results directory** - check **test_results_dir** for artifacts (screenshots, traces, logs).
3. **Test runner stdout** - parse the failure stack trace, assertion message, and step name.

**UI projects only - key rules for selector discovery:**
- Use the accessibility snapshot or page source, NOT guesswork
- Look for `button`, `link`, `tab`, `heading`, `textbox` roles with their actual names
- Check for `data-testid` attributes first - most reliable
- Note the element hierarchy - scoping selectors to parent containers prevents false matches
- Do not settle a locator that matches several elements with `.first()`. It can pick the wrong control and hide the ambiguity. Scope the locator to the element you mean, for example inside its row, dialog or form. Use `.first()` only when the first match is part of the behavior being tested.
- For component library dropdowns (MUI, Ant, etc.), prefer element IDs over role-based selectors to avoid strict mode violations
- **Escape regex specials when interpolating dynamic values into regex-based locators** - when a name-matching locator is built from a regex whose pattern was interpolated from an upstream value (an auto-discovered label, a file path, a formatted display string), characters like `(`, `)`, `.`, `[`, `]`, `?`, `+`, `*`, `|`, `\`, `^`, `$`, `{`, `}` are silently interpreted by the regex engine. The locator returns "no matches" even though the visible text matches the human's mental model exactly. Pipe the interpolated value through a regex-escape helper before constructing the regex. The smell that points at this bug: a snapshot-confirmed visible element that the locator still can't find

**Before fixing**, check if a **domain-knowledge** skill is configured in the BDD config. Invoke it to avoid known pitfalls.

##### 2c. Fix the implementation

Based on what you learned from the evidence:
1. Update the page objects or helpers
2. Update step definitions
3. Update support modules if needed
4. Build the feature in the application, but only when the step code is right and an assertion fails because the application does not do what the scenario says. An undefined step, a locator that finds nothing, a timeout or a setup error is a step problem: fix it in step code. Never change an approved scenario or its expected values to make it pass. If the scenario looks wrong, that is a product decision: report it as an open decision.

**Building the feature.** Check the **feature-builder** role in the BDD config. If it names a skill that you can find, invoke it to write the application code, and follow its standards. If it asks a question about behavior, report an open decision. If the row names a skill you cannot find, say so in one line and build it yourself. No **feature-builder**: build it yourself, with the smallest change that turns the scenario green. Ask for no approval before editing application code. The retry cap below applies. In the final report, list the application files you changed.

**Before authoring a NEW step def** (as opposed to editing an existing one), repeat the paraphrase grep from Phase 0 step 5 against the current inventory. The inventory may have changed since Phase 0 (e.g., a sibling scenario was implemented in between, or a step def merged upstream). If a paraphrase now exists, reword the `.feature` instead of adding a duplicate.

**Import discipline** - author imports just-in-time for what the current edit actually references. Do NOT pre-import symbols you "might use" later, and do NOT carry over imports from a prior draft that the final step body no longer references. Unused imports become typecheck failures under strict unused checks (for example `--noUnusedLocals` in TypeScript or `-warnaserror` in .NET) and require a follow-up cleanup PR. Before exiting Phase 2c, scan the file for imports introduced in this iteration and confirm each one is referenced by the code you just wrote.

##### 2d. Verify the fix

Re-run the test. If the group now passes, move to the next group. If a group fails, fix the failing step, then split the rest of that group in half and run each half in turn. A run with no tests executed is not a pass. If not, repeat 2b-2d.

**Max retries per step: 3.** If a step fails 3 times, stop and report what you've learned from the evidence. The user may need to provide guidance.

**Reporting an open decision.** When a stop is a product decision and not a technical one, for example the data does not fit the scenario or the code shows a behavior nobody described, report it in this shape, so that a caller can turn it into one question for the product owner:

```
Open decision: <the behavior in one plain sentence>
Found: <what the implementation or the run showed>
Options: <the choices, in plain words>
```

#### Phase 2.5: Red-first check

The red-first check shows that a scenario can fail for the reason it states. A green that was never seen red is not evidence. Run it once per scenario, after every group has passed and before the verifier is dispatched.

1. If a natural red was kept in 2a, the check is done. Report it and go to Phase 3.
2. Otherwise make a forced red. Take the last `Then` step of the scenario. Hold the original text of the file or helper you will change, in the loop and not from git. Change one thing so that the assertion must fail, for example the expected value in a comparison. The change goes in step code or in a helper that step uses. Never break a `.feature` file or a data file.
3. Run the **test** command for the scenario, as in 2a. The break is a red only if the scenario fails on an assertion in that step, with an expected-versus-actual message. An undefined step, a timeout, a setup or auth error, or a compile or type error is not a red. Undo the break and try once with a smaller break. If that is not a red either, stop trying.
4. When the run is done, restore the original text and check that the diff against it is empty. If you cannot confirm that, stop and name the file. The verifier's run in Phase 3 is the green after the restore.
5. If there was no red, the scenario is "not seen red". Say why in one line, for example "the break did not change the result", "the assertion is in generated code" or "no assertion step".

Report one line per scenario: `Red-first: natural, failed in <step>: <short message>`, `Red-first: forced, failed in <step>: <short message>`, or `Red-first: not seen red: <reason>`.

At the start of a run, if a file under the **steps_dir** has uncommitted changes you did not make, list them before you begin. One of them may be a break left behind by an interrupted run. Do not revert anything yourself.

#### Phase 3: Full Scenario Verification

After the verifier reports PASS for a scenario from an approved spec, remove the unautomated tag (the **unautomated_tag** row, default `@pending`) from it. If an **automated_tag** is configured, add it. Do this only after the verifier step below has passed. Never touch spec id tags (`@<scenario_id_prefix>...`). If implementing changes a scenario's text, say that its fingerprint will drift and that a `rewords` record is needed when the decision log is on.

A verifier verdict of "no tests ran" or "executed count unknown" is a FAIL: do not change any tag.

Remove the unautomated tag only when the scenario also has a red-first line that is not "not seen red". A scenario that was not seen red keeps the unautomated tag, and the report says why.

**Defaults when config rows are absent.** A value in `<...>` form counts as empty.

1. **unautomated_tag** absent or empty: use `@pending`.
2. **automated_tag** absent or empty: add nothing.
3. The scenario does not carry the unautomated tag: change no tags and say "no tag changes: scenario carries no unautomated tag".
4. The scenario is not from an approved spec: do not touch its tags.
5. Add the automated tag only when the unautomated tag was removed.
6. End the report with one line saying which tags changed, or that none did.

Once all steps pass individually, dispatch the **verifier** agent (from BDD config) for end-to-end verification:

```
Scope: strict
Project: <project>
By: tag
Select: <scenario-tag>
```

Use `By: name` with `Select: <scenario name>` when the scenarios carry no tag, or `By: file` with the feature file path.

The verifier runs the full scenario (without any visual-debug flag) and the strict type check. Failures must be resolved before declaring the scenario done - re-dispatch after each fix.

If dispatching the agent is not possible, run manually: the **prepare** command, then the **generate** command, then the **test** command, then the **typecheck** command (all from BDD config). All must pass with zero errors before the scenario is considered complete.

**Common typecheck failures and how to resolve them:**
- **Unused import / local / parameter** (e.g., `TS6133 declared but never read` in TypeScript projects) - delete the offending line. Use the `_`-prefix convention ONLY when an unused function parameter must remain to satisfy an interface or callback signature; never to silence an unused top-level import.
- **Missing import** (e.g., `cannot find name`) - add the import; verify the resolved path matches the project's module resolution config.
- **State-fixture property errors** - declare the new property on the **state_type** per Code Quality Rules below; don't paper over with `as any`.

After failure, inspect the artifacts in the **test_results_dir**. UI examples:
- `error-context.md` - accessibility snapshot at failure
- `video.webm` - browser recording
- `trace.zip` - open with the **show-trace** command

---

### BDD Conventions

Example from a Playwright and TypeScript project. Other stacks use their equivalents (see **state_fixture** and the **domain-knowledge** skill).

| Pattern | Wrong | Right |
|---------|-------|-------|
| Share state between steps | `this` context | **state_fixture** (mutable object, see BDD config) |
| Extend test base | Import from test framework | Import from BDD framework wrapper |
| Attach evidence | Direct in step | `$testInfo.attach()` fixture |
| Step parameter types | Hardcoded strings | Use Cucumber expressions (`{string}`, `{int}`, `{float}`) |
| Background steps | Re-run expensive setup | Cache results in state fixture, detect already-done state |

### Code Quality Rules

Read from `.claude/bdd-config.md` - the config is the single source of truth for quality rules. Key principles:

- **Typecheck must pass** with zero errors (run the **typecheck** command)
- **No unused code** - imports, locals, parameters, dead methods
- **State properties declared** - new properties on the state fixture must be added to the state type
- **Explicit file extensions** - where the module system requires explicit file extensions (Node ESM, TypeScript with node16 or nodenext resolution), imports include the `.js` extension
- **No `as any`** for properties that should be typed

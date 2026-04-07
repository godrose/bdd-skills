---
description: "Design BDD scenarios from user stories or ACs — analyze coverage gaps, formulate scenarios, audit step reuse, then implement"
allowed-tools: ["Agent", "Bash", "Read", "Grep", "Glob", "AskUserQuestion"]
---

## BDD Scenario Design

Design and formulate BDD scenarios from user stories, acceptance criteria, or feature requests. This is a **methodology skill** — it drives the what and why of scenario creation, then delegates implementation to the **implementer** skill.

Framework-agnostic: the design process works regardless of whether the underlying framework is Playwright, Cypress, Selenium, or any BDD runner.

**Before starting**, read `.claude/bdd-config.md` for project-specific tooling, conventions, and skill role mappings.

### Input

The user provides one or more of:
- An issue tracker URL or key (e.g., `PROJ-123`)
- Acceptance criteria text
- A feature area to cover (e.g., "user profile settings")
- A gap to fill (e.g., "we test field presence but not field values")

### Workflow

#### Phase 1: Understand the Requirements

1. **Fetch the source** — check if a **requirements-sync** skill is configured in the BDD config. If the input is an issue tracker key/URL, invoke it to fetch ACs, subtasks, comments, and linked issues. If no sync skill exists or the user provides AC text directly, use that as-is.
2. **Extract testable assertions** — for each AC bullet, identify concrete verifiable claims:
   - "User can view all records" → table displays all fields non-empty
   - "Downloaded data matches displayed data exactly" → export values = UI values
   - "Supported formats: CSV, JSON" → both formats downloadable with valid content
3. **Note ambiguities** — if an AC is vague, flag it for the user before designing scenarios

#### Phase 2: Audit Existing Coverage

1. **Scan feature files** — search the **features_dir** (from BDD config) for existing scenarios
2. **Map AC to existing scenarios** — which assertions are already tested?
3. **Identify gaps** — which AC bullets have no scenario coverage?
4. **Check step inventory** — search the **steps_dir** for existing Given/When/Then steps that new scenarios can reuse
5. **Present coverage matrix** to the user:

```
| AC Assertion                      | Covered by              | Gap? |
|-----------------------------------|-------------------------|------|
| Table shows all required fields   | (none)                  | YES  |
| Download matches UI exactly       | download.feature (partial) | YES — checks presence, not values |
| CSV and JSON supported            | download.feature        | No   |
```

#### Phase 3: Design Scenarios

For each gap, formulate a scenario following these principles:

**Scenario structure rules:**
- **One assertion per scenario** — don't combine "field completeness" and "download fidelity" in one scenario
- **Descriptive name** — the name should tell you what passes/fails without reading steps (e.g., "User profile displays all required fields")
- **Background for shared setup** — if 3+ scenarios share the same Given/When, extract to Background
- **Scenario Outline for parameterized** — if the same flow is tested with different inputs (CSV vs JSON), use Outline + Examples
- **Data Tables for lists** — field names, expected values, allowed statuses → DataTable, not hardcoded steps
- **Tags for routing** — `@PROJ-XXXX` for issue tracker linking, `@e2e`/`@smoke`/`@deep` for suite membership, scenario-specific tag for individual runs

**Step formulation rules:**
- **Reuse existing steps verbatim** — if a step already exists in the step inventory, use that exact text
- **New steps should be generic** — `Then the most recent row should have non-empty values for:` (reusable with DataTable) vs `Then the row should have name, email, status` (hardcoded)
- **Avoid implementation details in Gherkin** — `When I click the Download button` (good) vs `When I click [data-testid="download-btn"]` (bad)
- **Match the user's vocabulary** — use domain terms from the AC, not internal UI component names

**Ordering principles:**
- Start with the highest-value gap (most important AC, most likely to catch bugs)
- Group related scenarios in the same feature file
- Put simpler scenarios first (they validate infrastructure for complex ones)

#### Phase 4: Review with User

Present the designed scenarios to the user:
1. The proposed feature file(s) with full Gherkin text
2. Which steps are new vs reused
3. Which project/tag each scenario belongs to
4. Estimated implementation complexity (how many new steps, any new POM methods?)

**Wait for user approval before implementing.** The user may:
- Reorder priorities
- Merge or split scenarios
- Adjust step wording
- Add edge cases

#### Phase 5: Implement

For each approved scenario, invoke the **implementer** skill (from BDD config):

1. Write the `.feature` file (or add to existing)
2. Update the **config_file** if needed (new feature file in a project)
3. Invoke the **implementer** with the scenario tag
4. After each scenario passes, move to the next

If implementing multiple scenarios in the same feature file, implement them **in order** — Background steps are validated by the first scenario, subsequent ones build on that foundation.

#### Phase 6: Summary

After all scenarios are implemented and verified:
1. Report final pass/fail status per scenario
2. **Publish** — if a **requirements-sync** skill is configured, invoke it to push features and results to the test management tool. Verify the new scenarios appear linked to the source issue.
3. Update coverage matrix — all gaps should now be filled
4. Note any remaining gaps that require manual testing or backend changes

### Anti-Patterns

| Anti-Pattern | Why it's wrong | Do this instead |
|---|---|---|
| Design all scenarios, then implement all at once | Can't validate Background/shared steps until first scenario runs | Implement one at a time, in order |
| Copy AC text verbatim as scenario steps | ACs describe outcomes, not user actions | Translate to Given/When/Then user journey |
| One mega-scenario testing everything | Fails are ambiguous, hard to debug | One assertion per scenario |
| Skip coverage audit | May duplicate existing tests | Always check what exists first |
| Design scenarios without reading existing steps | Will create redundant step definitions | Audit step inventory in Phase 2 |
| Implement without user approval | User may have different priorities or wording preferences | Present and wait for approval in Phase 4 |

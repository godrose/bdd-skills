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
4. **Check step inventory (two passes — both required):**
   - **Pass A — exact match**: grep each drafted step verbatim against the **steps_dir** and existing `.feature` files
   - **Pass B — paraphrase audit**: for EACH new step, generate 2–3 natural paraphrases of the same assertion and grep them too. If any paraphrase hits, USE the existing wording. Paraphrase families to consider:
     - Success: "completes without error" / "exits cleanly" / "succeeds" / "returns no error"
     - Negation: "does not equal X" / "should not match X" / "differs from X"
     - Action verbs: "I copy / extract / read / capture" — the same intent often appears under several verbs
     - Container references: any phrase like "from the X tab / panel / page" — the existing step may identify the container differently
5. **Sweep project conventions** — before drafting NEW steps, read existing step defs in the same domain to learn the project's vocabulary:
   - **Negation form** — `is disabled` vs `is not enabled`; `should not match` vs `should differ`
   - **Data-table column names** already used in the same assertion family (e.g., `| field | matcher |` vs `| field | expected |`)
   - **Given-vs-When tense** for shared facts — if `When I open X` exists everywhere, don't invent `Given I have opened X` for a Background
   - **Composite-Given vs explicit-When-chain** patterns for `I have <state>` preconditions — prefer whichever pattern the rest of the suite already uses
6. **Present coverage matrix** to the user:

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
- **Reuse existing steps verbatim** — if a step (or a paraphrase you generated in Phase 2 Pass B) already exists, use that exact text. **Treat `@manual` scenarios with the same rigor** — today's @manual paraphrase becomes tomorrow's duplicate step def the moment it gets automated.
- **Collapse parallel string Thens into one DataTable Then** — if you're about to write ≥3 Thens of the form `the X should contain "Y"` (or any other parallel pattern), replace them with a single Then that takes a DataTable column listing the values. N+1 string Thens become 1 table-driven Then with N rows.
- **Match established data-table shapes** — if existing assertion steps in the same family use one set of column headers (e.g., `| field | matcher |`), use the same headers for the same fact. Don't invent a parallel convention (e.g., `| field | expected |`) — readers and step regex both fragment.
- **Don't tense-shift existing Whens into new Givens for Background** — if `When I open X` exists, REUSE that When in Background (even chained with sibling Whens that establish the precondition). Don't paraphrase as `Given I have opened X` just because Background slots typically carry Givens.
- **Match the project's negation convention** — read the inventory before drafting. If the codebase says `is disabled`, don't write `is not enabled`. If it says `should not point at`, don't write `does not point at`.
- **Multi-line content — use a DocString, never inline line breaks** — Gherkin step text is single-line. If a step needs a multi-line payload, place the payload in a Gherkin DocString (`"""…"""`) directly below a single-line step, never as line breaks inside a quoted step argument. Line breaks inside a quoted step argument fail Gherkin parsing.

  ```gherkin
  When I submit the following input:
    """
    line 1
    line 2
    """
  ```

  The step def signature takes a DocString parameter, not a quoted-string parameter. When a single-line form of the same input exists, prefer it — the scenario can reuse an existing single-argument step verbatim.
- **New steps should be generic** — `Then the most recent row should have non-empty values for:` (reusable with DataTable) vs `Then the row should have name, email, status` (hardcoded)
- **Avoid implementation details in Gherkin** — `When I click the Download button` (good) vs `When I click [data-testid="download-btn"]` (bad)
- **Match the user's vocabulary** — use domain terms from the AC, not internal UI component names

**Ordering principles:**
- Start with the highest-value gap (most important AC, most likely to catch bugs)
- Group related scenarios in the same feature file
- Put simpler scenarios first (they validate infrastructure for complex ones)

#### Phase 4: Review with User

Present the designed scenarios to the user. **Before requesting approval, produce a per-step reuse audit table — this is mandatory, not optional. It is the artifact that forces conscious reconciliation of every new step against the existing inventory.**

Example:

| Step Text | Status | Existing Analog |
|-----------|--------|------------------|
| `When I submit the form` | ✅ exact | `steps/forms.ts:42` |
| `Then the response should contain:` (table) | ⚠ paraphrase — prefer `the response should match:` | `steps/api.ts:88` |
| `Given the flag is not enabled` | ⚠ convention drift — codebase uses `is disabled` | `steps/flags.ts:17` |
| `Then a toast notification appears` | 🆕 genuinely new — no toast assertions exist yet | — |

**Resolve every ⚠ row before requesting approval** — either by rewording to the existing analog, or by documenting why the new wording is intentionally different. Then present:

1. The proposed feature file(s) with full Gherkin text
2. The per-step audit table above (every ⚠ should be either reconciled to ✅ or annotated `🆕 intentional because: <reason>`)
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
| Paraphrasing an existing step into new wording | Creates duplicate step defs with overlapping behavior; PR reviewers waste cycles spotting them | Phase 2 Pass B — generate 2–3 paraphrases of each drafted step and grep them against the inventory before finalizing |
| Multi-string Thens for an ordered/list assertion | N+1 step defs to maintain, each asserting one element of a fact that could be one DataTable assertion | Collapse ≥3 parallel `... should contain "X" ...` Thens into one DataTable Then |
| Tense-shifting an existing When into a Given for Background | The Given duplicates the When, requires a new step def, drifts from how the rest of the suite establishes the same precondition | Reuse the existing When-chain in Background, even if slightly verbose |
| Drift from established conventions (negation form, data-table column names) | The new wording looks fine in isolation but reads as inconsistent next to existing scenarios; locks in vocabulary forks | Phase 2 step 5 — sweep the inventory for vocabulary BEFORE drafting; match the project's word choice |
| Treating `@manual` scenarios as exempt from step-reuse rigor | Every @manual step becomes a step def when automated; paraphrases get locked in before anyone notices | Apply identical step-reuse rules to @manual and @automated scenarios |
| Presenting scenarios for approval without a per-step audit table | User can't tell which steps are new without manually grepping; review burden falls on reviewers, not the designer | Phase 4 — produce the audit table before requesting approval; every ⚠ row must be reconciled or annotated |
| Embedding multi-line content inside a quoted step argument | Fails Gherkin parsing | Use a single-line step with a Gherkin DocString (`"""…"""`) directly below it; the step def takes a DocString parameter |

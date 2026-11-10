---
description: "Design BDD scenarios from user stories or ACs: analyze coverage gaps, formulate scenarios, audit step reuse, then implement or stop at the approved spec"
---

## BDD Scenario Design

Design and formulate BDD scenarios from user stories, acceptance criteria, or feature requests. This is a **methodology skill** - it drives the what and why of scenario creation, then delegates implementation to the **implementer** skill.

Framework-agnostic: the design process works regardless of whether the underlying framework is Playwright, Cypress, Selenium, or any BDD runner.

**Before starting**, read `.claude/bdd-config.md` for project-specific tooling, conventions, and skill role mappings. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

### Input

The user provides one or more of:
- An issue tracker URL or key (e.g., `PROJ-123`)
- Acceptance criteria text
- A feature area to cover (e.g., "user profile settings")
- A gap to fill (e.g., "we test field presence but not field values")
- A discovery pack from `bdd:discover` (agreed examples, edge cases and exclusions)
- An approved checklist of agreed examples from `bdd:deliver`. That checklist counts as the approval of the examples, so do not ask for it again. Still show the scenarios in plain words and wait for the go-ahead.

### Mode

Read `workflow_mode` from `.claude/bdd-config.md`.

- `specify-and-implement`: the default. Design, get approval, implement, verify.
- `specify-only`: design and get approval, then stop. The scenarios are written as `.feature` files and left unautomated. A team uses this to put the scenarios in front of a product manager before any automation exists.

`--specify-only` or `--specify-and-implement` on the command overrides the config. If `workflow_mode` is absent, use `specify-and-implement`.

### Workflow

#### Phase 1: Understand the Requirements

If a discovery pack is given and its Readiness says it is not ready, say so and list what is missing before you design. Otherwise take its confirmed examples, edge cases and answered questions as the AC source. Skip the fetch and the ambiguity flag for anything the pack already settled.

1. **Fetch the source** - check if a **requirements-sync** skill is configured in the BDD config. If the input is an issue tracker key/URL, invoke it to fetch ACs, subtasks, comments, and linked issues. If no sync skill exists or the user provides AC text directly, use that as-is.
2. **Extract testable assertions** - for each AC bullet, identify concrete verifiable claims:
   - "User can view all records" → table displays all fields non-empty
   - "Downloaded data matches displayed data exactly" → export values = UI values
   - "Supported formats: CSV, JSON" → both formats downloadable with valid content
3. **List assumptions** - a term is vague when it names a category that covers more than one distinct value you find in the system or the existing features: states, roles, formats, units. "Finished" is vague if the system has Completed, Failed and Cancelled. A term with one possible meaning is not vague: do not list it. Do not stop to ask. Design with the narrowest sensible reading and record an assumption for it: the term as written, the reading chosen, the other readings found, and where you found them. If you cannot find the possible values, list the term as "values unknown, please confirm". Skip a term the discovery pack already settled.

#### Phase 2: Audit Existing Coverage

1. **Scan feature files** - search the **features_dir** (from BDD config) for existing scenarios
2. **Map AC to existing scenarios** - which assertions are already tested?
3. **Identify gaps** - which AC bullets have no scenario coverage?
4. **Check step inventory (two passes - both required):**
   - **Pass A - exact match**: grep each drafted step verbatim against every folder in the **steps_dir** (one path, or several comma-separated) and existing `.feature` files
   - **Pass B - paraphrase audit**: for EACH new step, generate 2–3 natural paraphrases of the same assertion and grep them too. If any paraphrase hits, USE the existing wording. Paraphrase families to consider:
     - Success: "completes without error" / "exits cleanly" / "succeeds" / "returns no error"
     - Negation: "does not equal X" / "should not match X" / "differs from X"
     - Action verbs: "I copy / extract / read / capture" - the same intent often appears under several verbs
     - Container references: any phrase like "from the X tab / panel / page" - the existing step may identify the container differently
   - **Pass C - assertion check**: for EACH reused `Then` step, read its step definition and note what it asserts (exact count, contains, order, exact text). Compare that claim with the data the scenario sets up. Same words do not mean the same claim: a step that asserts an exact count fails when the scenario's data has a different count. `Given` and `When` steps are not checked.
     - Definition cannot be read (shared or external library): record "assertion unknown" and flag it. Do not guess.
     - Step is planned and has no definition yet: compare against the scenario text only and record "assertion not checkable yet".
     - Step takes a parameter such as `{int}`: the parameter fits any value. Record it and pass.
     - Definition is long or indirect: record the visible assertion and say if a helper was followed. If you cannot tell, record "assertion unknown".
     - On a mismatch, the designer never changes fixture data and never rewrites the step silently. Flag it in the audit table and propose two fixes: (A) change the scenario's data, or (B) write a new step, marked `🆕 intentional because: <reason>`. Say which you prefer. The person chooses at the approval gate.
   - **Pass D - title check**: for EACH scenario drafted in this run, read its title and list the things it names: each entity, state or value. For each named thing, find the `Then` step that asserts it, and use the strength Pass C recorded. Write the result in the `Claims` column of that `Then` row. This check runs only for the scenarios drafted in this run. Scenarios already in the project are never checked, even when a drafted scenario reuses their steps.
     - A named thing that no `Then` step asserts: add a row with `(none)` as the step and flag it.
     - The title names an exact value and the step only checks that something is there (present, not empty, a count): flag it.
     - Every named thing is asserted: write "matches" in the `Claims` column. No finding.
     - Definition cannot be read, or the step is new: write "claim unchecked" and flag it. Do not guess. For a new step compare the title with the step's wording only, and say that is all that was compared.
     - A step that asserts more than the title says is not a finding.
     - On a finding, the designer never changes a title, fixture data or a step silently. Flag the row and propose two fixes: (A) narrow the title to what is asserted, or (B) add the missing assertion with a new or stronger step, marked `🆕 intentional because: <reason>`. Say which you prefer. The person chooses at the approval gate.

5. **Sweep project conventions** - before drafting NEW steps, read existing step defs in the same domain to learn the project's vocabulary:
   - **Negation form** - `is disabled` vs `is not enabled`; `should not match` vs `should differ`
   - **Data-table column names** already used in the same assertion family (e.g., `| field | matcher |` vs `| field | expected |`)
   - **Given-vs-When tense** for shared facts - if `When I open X` exists everywhere, don't invent `Given I have opened X` for a Background
   - **Composite-Given vs explicit-When-chain** patterns for `I have <state>` preconditions - prefer whichever pattern the rest of the suite already uses
6. **Present coverage matrix** to the user:

```
| AC Assertion                      | Covered by              | Gap? |
|-----------------------------------|-------------------------|------|
| Table shows all required fields   | (none)                  | YES  |
| Download matches UI exactly       | download.feature (partial) | YES - checks presence, not values |
| CSV and JSON supported            | download.feature        | No   |
```

#### Phase 3: Design Scenarios

For each gap, formulate a scenario following these principles:

**Scenario structure rules:**
- **One assertion per scenario** - don't combine "field completeness" and "download fidelity" in one scenario
- **Descriptive name** - the name should tell you what passes/fails without reading steps (e.g., "User profile displays all required fields")
- **Background for shared setup** - if 3+ scenarios share the same Given/When, extract to Background
- **Informational Background step for out-of-band prerequisites** - for setup the test ASSUMES but does not perform (long-lived state provisioned by another process: a configuration record, a seeded user, a deployed service version), declare an empty-bodied `Given <prerequisite> exists` step. The body is intentionally a no-op - the value is in the `.feature` file documenting what the scenario depends on, so a reader can tell at a glance what must be in place before the suite can run. Pair with the env-agnostic-identifiers rule below: the step should describe the prerequisite by KIND, not by real name
- **Scenario Outline for parameterized** - if the same flow is tested with different inputs (CSV vs JSON), use Outline + Examples
- **Data Tables for lists** - field names, expected values, allowed statuses → DataTable, not hardcoded steps
- **Tags for routing** - `@PROJ-XXXX` for issue tracker linking, `@e2e`/`@smoke`/`@deep` for suite membership, scenario-specific tag for individual runs, automation-type tag (e.g. `@automated` / `@manual`) when the test-management tool keys its automation badge on tags
- **Issue-tracker tags MUST repeat at the scenario level, not just on the Feature header** - Gherkin reporters (cucumber.json included) emit Feature-level tags and Scenario-level tags as **separate arrays** in the output; they do not merge. Test-management integrations that publish per-scenario results back to issue-tracker tickets read Scenario-level tags. A Feature header that carries `@PROJ-123` but whose scenarios don't will produce results that land without the link, even though the scenarios visibly inherit the tag at runtime. Always repeat the relevant issue-tracker tag on each scenario it covers - duplication with the Feature header is intentional
- **Automation-status tag, when the tool uses one, is a tag - not a side effect of pushing results** - many test-management tools decide whether a scenario shows as "Automated" vs "Manual" in the UI based on a scenario-level tag in the `.feature` file, NOT on whether a results upload exists for that scenario. Pushing a green run for a scenario that lacks the automation-type tag still leaves it badged "Manual". Audit the tool's convention once, add the tag to every executable scenario before the first sync, and re-sync the `.feature` (not just push results) after adding the tag
- **Manual by design** - for each scenario that needs a human (a GUI-only client, a physical device, a manual runbook), propose the **manual_only_tag** and let the builder confirm. Everything else is unautomated until implemented.

**Step formulation rules:**
- **Reuse existing steps verbatim** - if a step (or a paraphrase you generated in Phase 2 Pass B) already exists, use that exact text. **Treat planned (unautomated) scenarios with the same rigor** - today's planned paraphrase becomes tomorrow's duplicate step def the moment it gets automated.
- **Collapse parallel string Thens into one DataTable Then** - if you're about to write ≥3 Thens of the form `the X should contain "Y"` (or any other parallel pattern), replace them with a single Then that takes a DataTable column listing the values. N+1 string Thens become 1 table-driven Then with N rows.
- **Match established data-table shapes** - if existing assertion steps in the same family use one set of column headers (e.g., `| field | matcher |`), use the same headers for the same fact. Don't invent a parallel convention (e.g., `| field | expected |`) - readers and step regex both fragment.
- **Don't tense-shift existing Whens into new Givens for Background** - if `When I open X` exists, REUSE that When in Background (even chained with sibling Whens that establish the precondition). Don't paraphrase as `Given I have opened X` just because Background slots typically carry Givens.
- **Match the project's negation convention** - read the inventory before drafting. If the codebase says `is disabled`, don't write `is not enabled`. If it says `should not point at`, don't write `does not point at`.
- **Multi-line content - use a DocString, never inline line breaks** - Gherkin step text is single-line. If a step needs a multi-line payload, place the payload in a Gherkin DocString (`"""…"""`) directly below a single-line step, never as line breaks inside a quoted step argument. Line breaks inside a quoted step argument fail Gherkin parsing.

  ```gherkin
  When I submit the following input:
    """
    line 1
    line 2
    """
  ```

  The step def signature takes a DocString parameter, not a quoted-string parameter. When a single-line form of the same input exists, prefer it - the scenario can reuse an existing single-argument step verbatim.
- **New steps should be generic** - `Then the most recent row should have non-empty values for:` (reusable with DataTable) vs `Then the row should have name, email, status` (hardcoded)
- **Avoid implementation details in Gherkin** - `When I click the Download button` (good) vs `When I click [data-testid="download-btn"]` (bad)
- **Match the user's vocabulary** - use domain terms from the AC, not internal UI component names
- **Don't hardcode environment-specific identifiers in step arguments** - when a step references a real-world artefact (a record name, a hostname, a file path, a customer ID, an account label), the `.feature` should refer to it abstractly via a KIND token plus a POSITIONAL or SEMANTIC selector, and the step impl should resolve the actual identifier from env/profile config at runtime. Hardcoded identifiers (`"prod-db-east"`, `"host-42.example.com"`, `"customer 1289"`) lock the scenario to one environment - the same `.feature` can't run against staging, prod, or a CI sandbox without editing Gherkin. Good: `When I open the first record of kind "<kind>"`. Bad: `When I open the record named "<env-coupled-identifier>"`

**Ordering principles:**
- Start with the highest-value gap (most important AC, most likely to catch bugs)
- Group related scenarios in the same feature file
- Put simpler scenarios first (they validate infrastructure for complex ones)

#### Phase 4: Review with User

Present the designed scenarios to the user. **Before requesting approval, produce a per-step reuse audit table - this is mandatory, not optional. It is the artifact that forces conscious reconciliation of every new step against the existing inventory.**

Example:

| Step Text | Status | Existing Analog | Asserts | Claims |
|-----------|--------|------------------|---------|--------|
| `When I submit the form` | ✅ exact | `steps/forms.ts:42` | n/a (When) | n/a |
| `Then the list shows 2 experiments` | ⚠ assertion mismatch - asserts exact count, scenario data has 3 | `steps/list.ts:31` | exact count | matches |
| `Then the response should contain:` (table) | ⚠ paraphrase - prefer `the response should match:` | `steps/api.ts:88` | contains rows | matches |
| `Given the flag is not enabled` | ⚠ convention drift - codebase uses `is disabled` | `steps/flags.ts:17` | n/a (Given) | n/a |
| `Then a toast notification appears` | 🆕 genuinely new - no toast assertions exist yet | - | n/a | claim unchecked (new step, title compared with its wording only) |
| (none) | ⚠ the title says "reports its waiting time and run time", no step asserts the waiting time | - | - | ⚠ named thing not asserted |

**Resolve every ⚠ row before requesting approval** - either by rewording to the existing analog, or by documenting why the new wording is intentionally different. Then present:

1. The proposed feature file(s) with full Gherkin text. Write every scenario out in full, with all of its steps. Do not abbreviate a scenario with "same set-up as scenario 1" or a similar shortcut, even when scenarios repeat steps. The person approving must see the exact text that will be written.
2. The per-step audit table above (every ⚠ should be either reconciled to ✅ or annotated `🆕 intentional because: <reason>`)
3. Which project/tag each scenario belongs to
4. Estimated implementation complexity (how many new steps, any new POM methods?)

**Lint the draft before it is shown.** Skip this when the **lint** row is empty. Otherwise:

1. Write the draft to a temp file inside **features_dir**, named `.bdd-draft-<feature>.feature`. If a leftover `.bdd-draft-*` file from an interrupted run is there, report it first and ask whether to delete it.
2. Run the **lint** row. The row may scan the whole folder, so keep only the findings in the draft file. Say in one line "N findings in existing files, not touched". Never edit those files.
3. Fix the draft's findings. When a finding needs a value you cannot know (for example a ticket id), ask the user for the value, then add it. Stop after two rounds and list the findings that remain. Ignore a finding that is only about the temp file and its own name (the `.bdd-draft-` prefix), and report that you did.
4. The temp file is deleted before the draft is shown. Delete only the file you created in this run.
5. If the lint run fails for a reason other than findings (for example, missing tooling), warn and continue. Show one line: "lint did not run: <error>. The scenarios are unchecked." Do not install tooling.
6. Show "lint: no findings", or the findings that remain, with the draft.

Show the scenarios in plain words first, so the person approving sees what they will get. The audit table follows. Start the proposal with the **Assumptions** list from Phase 1. Write "Assumptions: none" when there are none. If the person picks another reading at the approval gate, update the affected scenarios and the list.

In `specify-only` mode, also produce a **spec PR summary** for a reader who has not seen the step library. Give it these sections:

- **Story to scenarios**: each part of the story and the scenarios that cover it.
- **Cases included**: the cases the scenarios cover.
- **Cases deliberately excluded**: cases left out, each with a reason.
- **New terms**: words the scenarios introduce, each with a reason.
- **Assumptions**: the approved list from Phase 1, one line per term with the reading chosen and the other readings found. Omit this section when there are none.
- **Step status**: the audit table above, with each step marked "existing (automated)", "existing (not yet automated)" or "new (to be built)". Mark a step "existing (automated)" only when a step definition for it exists in the **steps_dir**. A step that appears only in unautomated scenarios is "existing (not yet automated)".

**Wait for user approval before implementing.** The user may:
- Reorder priorities
- Merge or split scenarios
- Adjust step wording
- Add edge cases

#### Phase 5: Implement

When the request came from `bdd:deliver`, the go-ahead can come from either the product manager or the developer. Write each answer that shaped a scenario as one line in the text under `Feature:` of the `.feature` file: `Decision (YYYY-MM-DD): <answer>. Why: <reason>.` Write it in the same change as the scenarios.

In `specify-only` mode, do not implement. Write the `.feature` files and tag each scenario with the project's unautomated tag (the **unautomated_tag** row, default `@pending`), placed where **status_scope** says (default `scenario`): a scenario tag, a feature tag, or a directory (**planned_dir**, and **manual_only_dir** for manual-only scenarios). With directory scope and a partly approved feature, say that automated scenarios live in the automated directory and the rest stay. Scenarios that carry the **manual_only_tag** are not tagged as planned. Save the spec PR summary beside the feature file as `<feature>.spec-summary.md`. Then run the **generate** command once. If it fails on undefined steps, report that and point the builder at the framework setting that defers missing steps to run time (for Playwright-BDD, `missingSteps: 'fail-on-run'` in the Playwright config). Do not add a tag filter to the generate row: `implement` must generate the scenario it is working on, and that scenario keeps its tag until the verifier passes. Do not work around the failure. In `specify-only` mode the designer does not invoke the implementer. Say how to resume: run `/bdd:implement <feature path>` after the scenarios are approved. Then skip to Phase 6.

**Decision log.** Read **decision_log**. When it is `on` and the change passes the size gate (more than a wording fix), then after approval, in both modes:

> Plugin note: the decision log script is not part of the plugin. If `decision_log` is `on` and the script path below is not a file, say "The decision log needs the project install of this repository, which provides the script. Nothing was recorded.", go on without records, and do not search for the script elsewhere.

1. Write a decision record to `<decisions_dir>/<story>.jsonl` for each approved scenario and each exclusion. Take `fp` from `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh fingerprint <spec-id> --features <features_dir>`.
2. Tag each scenario with `@<scenario_id_prefix><slug>`. Never change an id once written.
3. Run the **lint** row, then `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh check`, and show the result.
4. Add the output of `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh show <story>` to the spec summary as a **Decisions** section.

When the log is off, none of this happens.

For each approved scenario, invoke the **implementer** skill (from BDD config):

1. Write the `.feature` file (or add to existing)
2. Update the **config_file** if needed (new feature file in a project)
3. Invoke the **implementer** with the scenario tag
4. After each scenario passes, move to the next

If implementing multiple scenarios in the same feature file, implement them **in order** - Background steps are validated by the first scenario, subsequent ones build on that foundation.

#### Phase 6: Summary

In `specify-only` mode, report the scenarios written and where the spec PR summary is, instead of pass or fail status. If a **requirements-sync** skill is configured, sync the `.feature` files so the scenarios show on the ticket. In this mode there are no results to push yet.

After all scenarios are implemented and verified:
1. Report final pass/fail status per scenario
2. **Publish** - if a **requirements-sync** skill is configured, invoke it to push features and results to the test management tool. Verify the new scenarios appear linked to the source issue.
3. Update coverage matrix - all gaps should now be filled
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
| Paraphrasing an existing step into new wording | Creates duplicate step defs with overlapping behavior; PR reviewers waste cycles spotting them | Phase 2 Pass B - generate 2–3 paraphrases of each drafted step and grep them against the inventory before finalizing |
| Multi-string Thens for an ordered/list assertion | N+1 step defs to maintain, each asserting one element of a fact that could be one DataTable assertion | Collapse ≥3 parallel `... should contain "X" ...` Thens into one DataTable Then |
| Tense-shifting an existing When into a Given for Background | The Given duplicates the When, requires a new step def, drifts from how the rest of the suite establishes the same precondition | Reuse the existing When-chain in Background, even if slightly verbose |
| Drift from established conventions (negation form, data-table column names) | The new wording looks fine in isolation but reads as inconsistent next to existing scenarios; locks in vocabulary forks | Phase 2 step 5 - sweep the inventory for vocabulary BEFORE drafting; match the project's word choice |
| Treating planned (unautomated) scenarios as exempt from step-reuse rigor | Every planned step becomes a step def when automated; paraphrases get locked in before anyone notices | Apply identical step-reuse rules to planned and automated scenarios |
| Abbreviating scenarios in the proposal ("same set-up as ...") | The approver signs off on text they have not seen, and the written file may differ from what they read | Phase 4 - write every scenario out in full with all of its steps |
| Assuming a reused Then step makes the claim the scenario needs | Same words means same claim is false: the step passes the wording audit and fails at run time on data it does not fit | Phase 2 Pass C - read the definition, record what it asserts in the `Asserts` column, flag a mismatch for the person to resolve |
| Trusting a title because the steps pass | A scenario can pass while it proves less than its title says. Asserting less than the title claims shows up as a green row with a promise the steps do not keep | Phase 2 Pass D - list what the title names, find the `Then` step for each, fill the `Claims` column, flag a gap and offer two fixes |
| Silently picking one meaning of a vague AC term | The other readings vanish and the person approving never sees the choice | Phase 1 step 3 - list the assumption with the other readings found, and show it first in the proposal |
| Presenting scenarios for approval without a per-step audit table | User can't tell which steps are new without manually grepping; review burden falls on reviewers, not the designer | Phase 4 - produce the audit table before requesting approval; every ⚠ row must be reconciled or annotated |
| Embedding multi-line content inside a quoted step argument | Fails Gherkin parsing | Use a single-line step with a Gherkin DocString (`"""…"""`) directly below it; the step def takes a DocString parameter |
| Issue-tracker tag only on the Feature header | The cucumber.json reporter writes Feature tags and Scenario tags into separate arrays. Test-management integrations that route per-scenario results to issue tickets read Scenario-level tags - Feature-level tags don't propagate. Results land without the issue link | Repeat the issue-tracker tag (`@PROJ-XXXX`) on every scenario it covers, in addition to the Feature header |
| Hardcoding real environment identifiers in `.feature` files (record names, hostnames, customer IDs, file paths, account labels) | The same `.feature` can no longer run against a second environment without editing Gherkin; profile-driven test runs become impossible; reviewers can't tell which arguments are environment-coupled vs scenario-essential | Use a KIND + positional/semantic selector in the step text ("the first record of kind X"); resolve real identifiers from env/profile config inside the step impl |
| Out-of-band prerequisite mentioned only in commit messages or PR descriptions | A reader of the `.feature` file alone can't tell what state the scenario relies on; first-time runners hit confusing assertion failures from missing setup | Declare an empty-bodied `Given <prerequisite> exists` Background step - body is a no-op, value is in self-documenting what must already exist |
| Assuming a `push-results` upload flips the test-management UI to "Automated" | Many test-management tools key the automation badge on a scenario-level tag in the `.feature` file, not on whether results have been pushed; result data lands fine but the badge stays "Manual" | Tag executable scenarios with the tool's automation-type tag (e.g. `@automated`) and re-sync the `.feature` after adding the tag |

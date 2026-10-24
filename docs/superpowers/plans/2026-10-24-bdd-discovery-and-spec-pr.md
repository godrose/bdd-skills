# BDD Discovery Stage and Spec-Only Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Evolve `godrose/bdd` so an individual builder gets agreed scenarios from a story through a discovery dialogue, with an optional spec-only pull request for teams, before any automation.

**Architecture:** Add one skill (`bdd-discover`) in front of `bdd-design`. Extend `bdd-design` with a mode switch (default `specify-and-implement`, opt-in `specify-only`) and a plain-language spec PR summary. Extend the config template with the new settings and keep every new setting optional with a documented default, so existing installs keep working. Skills are markdown and the installer is bash, so tests are bash scripts that run the installer and lint the skill files.

**Tech Stack:** Markdown skills for Claude Code, bash (`install.sh`, `tests/`). No new dependencies.

**Spec:** `docs/superpowers/specs/2026-10-24-bdd-methodology-design.md`

## Global Constraints

- Claude Code skills only (commands and agents under `.claude/`). No other agent formats.
- Default mode stays `specify-and-implement`. `specify-only` is opt-in.
- The primary audience is the individual builder. Discovery is a dialogue by default. A saved pack and the spec PR summary are opt-in team features.
- Step reuse is a hard rule in every stage. Reuse by default. A new step needs a stated reason.
- Skills reference each other by role from `bdd-config.md`, never by hardcoded name.
- Tracker binding (Jira, AssertThat) stays optional, behind the `requirements-sync` role.
- Re-running `install.sh` must not overwrite an existing `.claude/bdd-config.md`.
- Existing `bdd-config.md` files without the new rows must keep working (skills state the default for each absent row).
- No em-dashes in any new or edited text. Short, simple sentences.
- Existing skill text is not mass-edited. Only the sections named in a task change.

## Review Focus

- An old `bdd-config.md` with none of the new rows: every skill falls back to the documented default. Pinned in Tasks 3, 4 and 6.
- A story with no ACs or vague ACs: `bdd-discover` produces questions and stops, it does not invent scenarios. Pinned in Task 3.
- A story pasted as plain text with no tracker: works with no `requirements-sync` role. Pinned in Task 3.
- `specify-only` must never invoke the implementer, and the scenarios it leaves behind must be marked unautomated. Pinned in Task 4.
- Greenfield project with an empty `features_dir`: the vocabulary sweep reports "nothing to mine" and continues. Pinned in Task 3.
- `install.sh` run twice, and run on a project that already has a config: idempotent, config untouched. Pinned in Task 6.
- A trivial change (one-line fix, rename): `bdd-discover` applies the size gate and skips the dialogue instead of interrogating the builder. Pinned in Task 3.

## File Structure

| File | Responsibility |
|---|---|
| `tests/lib.sh` | Assertion helpers shared by all tests |
| `tests/run.sh` | Runs every `tests/test_*.sh`, exits non-zero on any failure |
| `tests/test_install.sh` | Installer behavior |
| `tests/test_skills.sh` | Structural lint of skill, agent and config files |
| `.claude/bdd-config.template.md` | New optional rows |
| `.claude/commands/bdd-discover.md` | New discovery skill |
| `.claude/commands/bdd-design.md` | Mode switch, discovery input, spec PR summary |
| `.claude/commands/bdd-implement.md` | Entry from an approved spec |
| `install.sh` | Install the new skill, warn about absent config rows |
| `README.md` | Flow, modes, install list |

---

### Task 1: Branch and test harness

**Files:**
- Create: `tests/lib.sh`, `tests/run.sh`, `tests/test_install.sh`, `tests/test_skills.sh`

**Interfaces:**
- Produces in `tests/lib.sh`: `assert_file <path>`, `assert_contains <path> <fixed-string>`, `assert_not_contains <path> <fixed-string>`, `assert_equals <expected> <actual> <label>`, `finish` (prints summary, exits non-zero if any assert failed).
- Produces: `tests/run.sh` (no args) runs all `tests/test_*.sh`.

- [ ] **Step 1: Create the branch and commit the design and plan**

```bash
git switch -c feat/discovery-and-spec-pr
git add docs/superpowers
git commit -m "docs: design and plan for discovery stage and spec-only mode"
```

- [ ] **Step 2: Write baseline tests that pin today's installer behavior**

In `tests/test_install.sh`: install into a `mktemp -d` project and assert `.claude/commands/bdd-design.md`, `bdd-implement.md`, `bdd-run.md`, `.claude/agents/bdd-verifier.md` and `.claude/bdd-config.md` exist; write `SENTINEL` into the config, re-run, assert `SENTINEL` is still there. In `tests/test_skills.sh`: for every `.claude/commands/*.md` and `.claude/agents/*.md` assert the first line is `---` and a `description:` or `name:` line exists.

- [ ] **Step 3: Run the harness**

Run: `bash tests/run.sh`
Expected: PASS (these pin existing behavior, so they must pass before any change).

- [ ] **Step 4: Commit**

```bash
git add tests && git commit -m "test: add installer and skill structure harness"
```

---

### Task 2: Config template gains the new settings

**Files:**
- Modify: `.claude/bdd-config.template.md`
- Test: `tests/test_skills.sh`

**Interfaces:**
- Produces config rows read by later tasks: Conventions `glossary_file` (optional path), `discovery_dir` (default `docs/discovery`); Tooling `lint` (optional project linter command); new `## Workflow` section with row `workflow_mode` (`specify-and-implement` default, or `specify-only`); Skill Roles row `discoverer` = `bdd-discover`, not required.

- [ ] **Step 1: Write the failing tests**

In `tests/test_skills.sh`: assert the template contains `workflow_mode`, `glossary_file`, `discovery_dir`, `| lint |`, `discoverer`.
- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL on the missing rows.

- [ ] **Step 3: Edit the template**

Add the rows above. Each optional row states its default in the Description or Value cell. The `discoverer` row points at `bdd-discover`, which Task 3 creates.

- [ ] **Step 4: Run and commit**

Run: `bash tests/run.sh`
Expected: PASS for the new rows.

```bash
git add .claude/bdd-config.template.md tests && git commit -m "feat(config): add workflow mode, glossary, discovery and lint settings"
```

---

### Task 3: `bdd-discover` skill

**Files:**
- Create: `.claude/commands/bdd-discover.md`
- Test: `tests/test_skills.sh`

**Interfaces:**
- Consumes: config rows from Task 2; the optional `requirements-sync` role.
- Produces: a discovery pack (markdown) that `bdd-design` accepts as input. Fixed section headings: `Story`, `Open questions`, `Candidate examples`, `Edge and negative cases`, `Vocabulary check`, `Candidate exclusions`, `Readiness`.

- [ ] **Step 1: Write the failing tests**

Add a check that every `bdd-*` name in the template's Skill Roles table resolves to a file under `.claude/commands/` or `.claude/agents/`. Assert `bdd-discover.md` has frontmatter, contains all seven headings above, contains a `Defaults when config rows are absent` section, contains the phrase `stop and ask` in a rule about missing or vague ACs, mentions `requirements-sync` as optional, mentions an empty `features_dir` ("nothing to mine"), mentions a size gate for trivial changes, says discovery is a dialogue with one question at a time, and contains no em-dash character (U+2014, match it with `printf '\xe2\x80\x94'`).

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL, file missing.

- [ ] **Step 3: Write the skill**

Frontmatter `description` and `allowed-tools` like `bdd-design`. Input: tracker key or URL, or pasted story text. Workflow rules the skill must state:
- Fetch via `requirements-sync` if configured and a key is given. Otherwise use the pasted text.
- Size gate: for a trivial change (one-line fix, rename, copy edit), say so and skip discovery.
- Run as a dialogue with the builder, one question at a time. Restate the story in plain words. If ACs are missing or vague, stop and ask. Do not draft scenarios.
- Propose concrete examples in the builder's words, not Gherkin. Propose negative paths and edge cases as questions ("what should happen when ...").
- Vocabulary sweep: mine `features_dir` and `steps_dir` for the project's terms and casing, add `glossary_file` terms if set, run the `lint` command if set, and list story terms that match nothing as "unknown, ask the PM". Empty `features_dir` reports "nothing to mine" and continues.
- List candidate exclusions as decisions for the PM to confirm, with a reason each.
- Keep the pack in the conversation by default. Save it to `discovery_dir`, named after the story key, only when the builder asks (team use: paste as a PR description or tracker comment).
- End with `Readiness`: ready for `bdd-design` only when no open question remains unanswered.
- Defaults section: absent `discovery_dir` means `docs/discovery`; absent `glossary_file` and `lint` mean skip those checks.

- [ ] **Step 4: Run and commit**

Run: `bash tests/run.sh`
Expected: PASS.

```bash
git add .claude/commands/bdd-discover.md tests && git commit -m "feat: add bdd-discover skill"
```

---

### Task 4: `bdd-design` modes, discovery input and spec PR summary

**Files:**
- Modify: `.claude/commands/bdd-design.md` (Input, Phase 1, Phase 4, Phase 5, Phase 6)
- Test: `tests/test_skills.sh`

**Interfaces:**
- Consumes: discovery pack from Task 3; `workflow_mode` from Task 2.
- Produces: in `specify-only` mode, `.feature` files plus a spec PR summary with fixed headings: `Story to scenarios`, `Cases included`, `Cases deliberately excluded`, `New terms`, `Step status`.

- [ ] **Step 1: Write the failing tests**

Assert `bdd-design.md` contains: `--specify-only`, `specify-only`, `specify-and-implement`, the five summary headings, a sentence that `specify-only` does not invoke the implementer, a sentence that scenarios are left unautomated under the project's unautomated tag, "discovery pack" as an accepted input, and a default statement that an absent `workflow_mode` means `specify-and-implement`. Assert the new text contains no em-dash by diffing against `git show main:.claude/commands/bdd-design.md` and checking added lines only.

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL.

- [ ] **Step 3: Edit the skill**

- Input: add "a discovery pack from `bdd-discover`". Phase 1: when a pack is given, take its agreed examples and answered questions as the AC source and skip re-fetching.
- Add a "Mode" subsection before Phase 1: read `workflow_mode`; `--specify-only` or `--specify-and-implement` on the command overrides it; absent means `specify-and-implement`.
- Phase 4 (review): the per-step reuse audit table stays. In `specify-only` mode also produce the spec PR summary. The `Step status` section reuses the audit table, labelled "existing (automated)" or "new (to be built)", and the summary is written for a PM who has not seen the step library.
- Phase 5: in `specify-only` mode stop after writing the `.feature` files, tag scenarios with the project's unautomated tag (default `@manual`), do not invoke the implementer, and say how to resume (`/bdd-implement <feature path>` after approval). In `specify-and-implement` mode Phase 5 is unchanged.
- Phase 6: in `specify-only` mode report scenarios written and the summary location instead of pass/fail.

- [ ] **Step 4: Run and commit**

Run: `bash tests/run.sh`
Expected: PASS.

```bash
git add .claude/commands/bdd-design.md tests && git commit -m "feat(bdd-design): add specify-only mode and spec PR summary"
```

---

### Task 5: `bdd-implement` entry from an approved spec

**Files:**
- Modify: `.claude/commands/bdd-implement.md` (Input, Phase 0)
- Test: `tests/test_skills.sh`

- [ ] **Step 1: Write the failing test**

Assert `bdd-implement.md` mentions an "approved spec", the spec PR summary `Step status` section, and the rule to remove the unautomated tag once a scenario passes. Added lines contain no em-dash.

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL.

- [ ] **Step 3: Edit the skill**

Input: accept scenarios written by a `specify-only` run. Phase 0: if a spec PR summary exists, read its `Step status` table, treat "new" rows as the work list, and stop and report if an "existing" step can no longer be found or a new step's wording differs from the approved scenario text (reword nothing silently). Phase 3: after the verifier passes, remove the unautomated tag from the scenario.

- [ ] **Step 4: Run and commit**

```bash
bash tests/run.sh
git add .claude/commands/bdd-implement.md tests && git commit -m "feat(bdd-implement): resume from an approved spec"
```

---

### Task 6: Installer

**Files:**
- Modify: `install.sh`
- Test: `tests/test_install.sh`

**Interfaces:**
- Produces: `bdd-discover.md` installed with the source header; a notice listing any of `workflow_mode`, `glossary_file`, `discovery_dir`, `lint`, `discoverer` missing from an existing config.

- [ ] **Step 1: Write the failing tests**

- Fresh install: `bdd-discover.md` exists and its second line starts with `# Source:`.
- Old config: pre-write a config containing none of the new rows plus `SENTINEL`; install; assert `SENTINEL` is intact and the output names `workflow_mode` as absent with its default.
- Idempotence: install twice; assert the second run exits 0 and the config is byte-identical to the first.

- [ ] **Step 2: Run to verify failure**

Run: `bash tests/run.sh`
Expected: FAIL.

- [ ] **Step 3: Edit `install.sh`**

Add `bdd-discover` to the install list and the printed list. After the config step, when the config pre-existed, grep it for each new row name and print a one-line notice per missing row with its default. Update the "Next steps" text to mention `/bdd-discover`. Leave the legacy cleanup block untouched.

- [ ] **Step 4: Run and commit**

```bash
bash tests/run.sh
git add install.sh tests && git commit -m "feat(install): install bdd-discover and report absent config rows"
```

---

### Task 7: README and end-to-end dry run

**Files:**
- Modify: `README.md`
- Create: `tests/fixtures/story.md` (a short sample story with one deliberately vague AC)

- [ ] **Step 1: Update the README**

Add `bdd-discover` to "What's included", draw the flow (story, discover, design, spec PR, PM review, implement, results back), describe the two modes and how to switch, and update the architecture diagram. Test: `tests/test_skills.sh` asserts the README mentions `bdd-discover` and `specify-only`.

- [ ] **Step 2: Run the tests**

Run: `bash tests/run.sh`
Expected: PASS.

- [ ] **Step 3: Dry run in a scratch project (manual, evidence required)**

Install into a temp project, open Claude Code there, run `/bdd-discover` on `tests/fixtures/story.md`. Expected: it stops and asks about the vague AC and does not write scenarios. Answer the questions, then run `/bdd-design --specify-only`. Expected: `.feature` files tagged `@manual`, a spec PR summary with the five headings, no implementer invoked. Paste the transcript excerpts into the PR description.

- [ ] **Step 4: Commit**

```bash
git add README.md tests && git commit -m "docs: describe discovery stage and modes"
```

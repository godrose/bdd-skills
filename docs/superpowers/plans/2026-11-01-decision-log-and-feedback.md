# Decision Log and Feedback Intake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in, append-only decision log (JSON Lines in git), a script that checks it and renders a story page, and two skills (`bdd-feedback`, `bdd-reconcile`), without changing behavior when the log is off.

**Architecture:** One bash+jq script, `.claude/scripts/decisions.sh`, with subcommands `check`, `fingerprint`, `status` and `show`. It reads a compact schema file. Two new skills call it. `bdd-design` and `bdd-implement` learn the new status vocabulary and write records when the log is on. `install.sh` ships the script and schema.

**Tech Stack:** bash 3.2 compatible shell, `jq` 1.6 or newer, `git`, `shasum` or `sha256sum`. Markdown skills. Tests are bash scripts in `tests/`.

**Spec:** `docs/superpowers/specs/2026-10-31-decision-log-and-feedback-design.md` (builds on `2026-10-24-bdd-methodology-design.md`)

## Global Constraints

- No em-dashes (U+2014) in any file added or changed. `assert_no_added_emdash` enforces it.
- Short, simple sentences. No redundant code comments.
- Bash 3.2 compatible: no associative arrays, no `mapfile`, no `${var,,}`.
- The script needs `jq`. With `decision_log` off, nothing calls it and `jq` is not needed.
- Gherkin keywords are English only. Localized keywords are not supported in v1.
- A regression test must fail before the code that fixes it. Never change an expected value to make a test pass.
- With the log off, skills behave as in v1, except the planned-marker default (`@pending`, see Task 8).
- Commit messages end with the two attribution lines from the session reminder (`Co-Authored-By` and `Claude-Session`).
- Run the whole suite (`bash tests/run.sh`) before each commit. Report any failure by name.

## Planning rulings

These extend or refine the spec. The final message lists them for the author.

1. The script is one file, `decisions.sh`, with subcommands. The spec named `check-decisions.sh` for the checks only.
2. `decision.schema.json` is a compact custom schema, not JSON Schema. The script reads its required-field lists and enums with `jq`, so the field lists live in one place. Cost if wrong: swap in a real validator later.
3. A fourth record field, `resolves`, and a third record kind, `open`, support the approved "Still open" block. They are in the spec now.
4. A spec id that tags more than one scenario is an error, `E-DUP-SCENARIO`.
5. The fingerprint is 8 hex characters of SHA-256 over the normalized scenario.
6. Directory-scope status needs two more config rows, `planned_dir` and `manual_only_dir`.
7. Status words in the story page are ASCII words, not glyphs.

## Review Focus

Input classes and failure modes the spec implies. Each has a test in the task that owns the code.

1. A spec id that appears in a comment, a docstring or a step line must not count as a scenario tag (Task 3).
2. Windows line endings, blank lines and a missing final newline in `.jsonl` and `.feature` files (Tasks 1 and 3).
3. First adoption: no decisions directory, an empty log, or a base commit that has no log yet (Tasks 1 and 2).
4. The same spec id on two scenarios, in one file or two (Tasks 3 and 4).
5. Decision text with pipes, quotes, asterisks and non-ASCII characters in the story page (Task 6).
6. `jq` missing: a clear message and exit code 2, never a silent pass (Task 1).

## File Structure

| File | Responsibility |
|---|---|
| `.claude/schemas/decision.schema.json` | Field lists and enums for record kinds. Single source for the script. |
| `.claude/scripts/decisions.sh` | `check`, `fingerprint`, `status`, `show`. |
| `.claude/commands/bdd-reconcile.md` | Skill: run the checks, judge contradictions, print the story page. |
| `.claude/commands/bdd-feedback.md` | Skill: pasted discussion to proposed edits and records. |
| `.claude/commands/bdd-design.md`, `bdd-implement.md` | Modified: log writing, status vocabulary. |
| `.claude/bdd-config.template.md` | New rows and roles. |
| `install.sh` | Ships script, schema and skills. Reports new rows. |
| `README.md` | Documents the log, feedback intake and story page. |
| `tests/test_decisions.sh` | Script tests. Picked up by `tests/run.sh` automatically. |
| `tests/test_skills.sh`, `tests/test_install.sh` | Extended. |

---

### Task 1: Schema and `decisions.sh check` structural validation

**Files:**
- Create: `.claude/schemas/decision.schema.json`, `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Produces, CLI: `decisions.sh check [--dir D] [--features F] [--prefix P] [--base REF]`. Defaults: `--dir` from `BDD_DECISIONS_DIR` or `docs/decisions`, `--features` from `BDD_FEATURES_DIR`, `--prefix` from `BDD_ID_PREFIX` or `spec-`. Flags beat env.
- Produces, output: one line per finding, `<LEVEL> <CODE> <file>:<line> <message>`, with LEVEL one of `ERROR`, `WARN`, `INFO`. The last line is `summary errors=N warnings=N`. Exit 0 when errors are 0, 1 when any error, 2 for usage errors or missing `jq`.
- Produces, internals later tasks reuse: a function that loads every record from `<dir>/*.jsonl` as JSON annotated with `_file` and `_line`; a `finding LEVEL CODE LOC MSG` emitter that counts errors and warnings.
- Produces, test helpers in `tests/test_decisions.sh`: `new_project` (temp dir with `docs/decisions` and `features`), `log_add PROJECT STORY JSON` (append a line), `add_feature PROJECT` (writes `features/export.feature` with one scenario tagged `@spec-header-row`), `check_in PROJECT [args]` (sets `OUT` and `RC`), `has STR` and `lacks STR` (assert on `OUT`).
- Schema shape: `supported_versions` (array), `kinds.<kind>.required` for `decision`, `confirms` and `open`, `enums.effect_op`, `enums.source_role`, `enums.source_kind`, `effect_required.<op>`.

Schema content to write (required lists exact):

```json
{
  "description": "Compact schema for BDD decision log records. Read by decisions.sh.",
  "supported_versions": [1],
  "kinds": {
    "decision": {"required": ["v", "id", "kind", "story", "at", "text"]},
    "confirms": {"required": ["v", "id", "kind", "of", "at", "sources"]},
    "open":     {"required": ["v", "id", "kind", "story", "at", "text"]}
  },
  "enums": {
    "effect_op": ["adds", "changes", "rewords", "removes", "excludes", "defers"],
    "source_role": ["proposed", "agreed", "objected"],
    "source_kind": ["slack", "jira", "pr", "meeting", "other"]
  },
  "effect_required": {
    "adds": ["scenario", "fp"], "changes": ["scenario", "fp"], "rewords": ["scenario", "fp"],
    "removes": ["scenario"], "excludes": ["phrase"], "defers": ["phrase"]
  }
}
```

Validation rules for `check` in this task:
- Each non-blank line is valid JSON (`E-JSON`). Strip a trailing CR first. A missing final newline is fine.
- `v` is in `supported_versions`, else `E-VERSION` with "update the skills" in the message.
- Required fields per kind, effect fields per op, enum values for op, source role and source kind: `E-SCHEMA`.
- The record `id` starts with the file's base name plus `-` (file `S.jsonl`, id `S-01`): `E-SCHEMA`.
- A scenario named in an effect matches `^<prefix>[a-z0-9-]+$`: `E-SCHEMA`.
- Ids are unique across all files: `E-DUP-ID`.
- Every id in `supersedes`, `resolves` and `of` exists: `E-REF`.
- A missing or empty decisions directory gives `INFO I-EMPTY no decision records` and exit 0.

- [ ] **Step 1: Create the branch and commit the spec and plan**

Run: `git switch -c feat/decision-log-and-feedback && git add docs/superpowers/specs/2026-10-31-decision-log-and-feedback-design.md docs/superpowers/plans/2026-11-01-decision-log-and-feedback.md && git commit -m "docs: design and plan for decision log and feedback intake"`
Expected: a commit on the new branch.

- [ ] **Step 2: Write the failing tests** in `tests/test_decisions.sh`

Start the file like the other tests (`ROOT`, `. lib.sh`, `T=$(mktemp -d)`, trap, `finish` last). Define `SCRIPT="$ROOT/.claude/scripts/decisions.sh"` and the helpers listed above. The valid record used by most tests, called `D_OK`:

```bash
D_OK='{"v":1,"id":"S-01","kind":"decision","story":"S","at":"2026-10-31","text":"Header row is exported.","effects":[{"op":"adds","scenario":"spec-header-row","fp":"aaaaaaaa"}]}'
```

`add_feature` is part of every project that has a spec-tagged effect, so the Task 4 orphan check does not break these tests later. Cases (each builds a fresh project):

| Case | Setup | Assertions |
|---|---|---|
| valid log | `D_OK`, feature | `RC=0`, `has "summary errors=0"` |
| bad JSON | `D_OK` plus `{not json` | `RC=1`, `has "ERROR E-JSON"`, `has "S.jsonl:2"` |
| missing field | `D_OK` without `text` | `has "ERROR E-SCHEMA"` |
| future version | `D_OK` with `"v":2` | `has "ERROR E-VERSION"`, `has "update the skills"` |
| bad op | effect op `"burns"` | `has "ERROR E-SCHEMA"` |
| bad source role | a `confirms` record with role `"maybe"` | `has "ERROR E-SCHEMA"` |
| id vs file name | `D_OK` in `OTHER.jsonl` | `has "ERROR E-SCHEMA"` |
| bad scenario id | scenario `"Spec_Header"` | `has "ERROR E-SCHEMA"` |
| duplicate id | the same `D_OK` line twice in `S.jsonl` | `has "ERROR E-DUP-ID"` |
| dangling refs | `supersedes`, `resolves` and `of` each naming `S-99` | three `ERROR E-REF` lines |
| CRLF, blank line, no final newline | `D_OK` written with `\r\n`, a blank line, and no trailing newline | `RC=0` |
| no decisions dir | project without `docs/decisions` | `RC=0`, `has "I-EMPTY"` |
| empty file | zero-byte `S.jsonl` | `RC=0` |
| no jq | `PATH=/nonexistent /bin/bash "$SCRIPT" check` | `RC=2`, output names `jq` |
| flags beat env | `BDD_DECISIONS_DIR=bogus` plus `--dir docs/decisions` | `RC=0` |

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: failures that the script or schema is missing.

- [ ] **Step 4: Implement** the schema file and `decisions.sh` with the `check` subcommand and the shared loader and emitter. The script resolves the schema as `"$(dirname "$0")/../schemas/decision.schema.json"`, so it works from the repo and from an installed `.claude/`. It checks for `jq` first.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0` everywhere.

- [ ] **Step 6: Commit**

```bash
git add .claude/schemas .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): decision schema and structural check"
```

---

### Task 2: Append-only check against a base ref

**Files:**
- Modify: `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Consumes: Task 1's loader, emitter and test helpers.
- Produces: `check --base REF`. It compares each log file in the working tree with `git show REF:<path>`. Error code `E-APPEND` when a base file is deleted, or when its lines are not an exact prefix of the working-tree file. New files and appended lines pass. A base that has no log directory passes. A non-git directory with `--base` exits 2.
- Produces: a helper that lists record ids present at REF (used by Tasks 4 and 6 for "new since").

- [ ] **Step 1: Write the failing tests**

Each case makes a git repo (`git init`, `-c user.name=t -c user.email=t@t` on commits), commits a log with `D_OK`, then changes it and runs `check --base HEAD`:

| Case | Change | Assertions |
|---|---|---|
| append | add a second valid line | `RC=0` |
| edit | change `text` in line 1 | `RC=1`, `has "ERROR E-APPEND"` |
| delete line | remove line 1 | `has "ERROR E-APPEND"` |
| delete file | `rm` the log file | `has "ERROR E-APPEND"` |
| new file | add `T.jsonl` | `RC=0` |
| first adoption | base commit has no `docs/decisions` | `RC=0` |
| CRLF base | base file stored with CRLF, working copy LF, same content | `RC=0` |
| not a repo | no `.git`, `--base HEAD` | `RC=2` |
| union merge | `.gitattributes` has `docs/decisions/*.jsonl merge=union`. Two branches each append a different line. Merge. | merge exits 0 and both lines are present |

The last case verifies the assumption behind the spec's merge advice.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: the new cases fail (`--base` unknown).

- [ ] **Step 3: Implement** `--base`. Compare line by line after stripping CR. Do not rely on `git diff` output parsing for the prefix rule.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): append-only check against a base ref"
```

---

### Task 3: Scenario lookup and `decisions.sh fingerprint`

**Files:**
- Modify: `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Consumes: flag parsing from Task 1.
- Produces, CLI: `decisions.sh fingerprint ID --features F`. Prints 8 hex characters. Exit 1 with `not found` or `ambiguous` on stderr when the id tags no scenario or more than one.
- Produces, internal: `scan_scenarios` that walks every `*.feature` under `--features` once and emits, per scenario keyword line: file, line number, scenario name, the tags attached to it, the tags attached to its `Feature:` line, and the block's line range. Tasks 4, 5 and 6 reuse it.
- Attachment rule: tag lines (trimmed text starts with `@`), comment lines and blank lines accumulate. A `Scenario`, `Scenario Outline`, `Scenario Template` or `Example:` line takes the accumulated tags. A `Feature:` line takes them as feature tags. Any other line clears them.
- Block: from the keyword line to the line before the next line that starts (trimmed) with `@`, a scenario keyword, `Feature:`, `Rule:` or `Background:`. `Examples:` stays inside the block.
- Normalization for the hash: strip CR, drop tag lines and comment lines, trim each line, collapse runs of whitespace to one space, drop blank lines, join with LF, SHA-256, first 8 hex. Use `shasum -a 256` when present, else `sha256sum`.

- [ ] **Step 1: Write the failing tests** (a small `.feature` is written inline per case; `fp_of ID` wraps the subcommand)

| Case | Setup | Assertions |
|---|---|---|
| stable under noise | same scenario with extra tags, a comment, extra spaces, blank lines, CRLF | equal fingerprints |
| step change | one step reworded | different fingerprint |
| outline examples | change one Examples cell | different fingerprint |
| status tag flip | `@pending` removed | equal fingerprint |
| id in a comment | `# @spec-header-row` only | exit 1, `not found` |
| id in a step | `Given a note says @spec-header-row` | exit 1, `not found` |
| id on the Feature line | tag above `Feature:` | exit 1, `not found` |
| duplicate id | two scenarios in one file carry the id | exit 1, `ambiguous` |
| duplicate across files | one in each of two files | exit 1, `ambiguous` |
| two ids, one scenario | a scenario carries two spec ids | each id fingerprints to the same value |
| no final newline | feature file without trailing newline | exit 0 |

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: the new cases fail (`fingerprint` unknown).

- [ ] **Step 3: Implement** `scan_scenarios` (awk is a good fit) and `fingerprint`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): scenario lookup and fingerprint"
```

---

### Task 4: Live decisions and reconciliation findings

**Files:**
- Modify: `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Consumes: loader (Task 1), `--base` id list (Task 2), `scan_scenarios` and fingerprint (Task 3).
- Produces, one jq state function used by `check` and `show`, with these definitions:
  - **Global order:** records sorted by `at`, then file name, then line.
  - **Superseded:** an id named in any decision's `supersedes`.
  - **Standing effect:** `adds`, `changes` and `rewords` stand until a later `removes` of the same scenario. `removes`, `excludes` and `defers` always stand. A decision with no effects stands.
  - **Live decision:** not superseded, and at least one effect stands. A decision whose scenario effects were all removed later, and which has no other effect, is closed.
  - **Latest fingerprint of scenario S:** the `fp` of the last `adds`, `changes` or `rewords` effect on S in global order.
  - **Open item:** an `open` record whose id no decision lists in `resolves`.
- Produces, findings from `check` (needs `--features`):
  - `E-DUP-SCENARIO` when a spec id tags more than one scenario.
  - `E-ORPHAN` when a live decision has a standing scenario effect and the scenario is absent.
  - `W-DRIFT` when the scenario's fingerprint differs from its latest fingerprint.
  - `W-UNDECIDED` when a spec-tagged scenario has no live decision with a standing effect on it.
  - `W-CONFLICT` when two live decisions supersede the same id.
  - `I-LEGACY` with the count of scenarios that have no tag starting with the prefix.
- Produces, scope: with `--base REF`, `E-ORPHAN`, `W-DRIFT` and `W-UNDECIDED` are reported only for touched scenario ids, and `W-CONFLICT` only when one of the two decisions is new since REF. Touched ids are the scenario ids in new records, the spec ids in `.feature` files changed since REF, and spec ids present at REF under the features directory but absent now. Without `--base`, everything is reported.

- [ ] **Step 1: Write the failing tests.** Feature fixture: the `add_feature` scenario. `fp` values in records come from `fingerprint` at test time, never hard-coded.

| Case | Setup | Assertions |
|---|---|---|
| healthy | one `adds` with the real fp | `has "summary errors=0 warnings=0"` |
| orphan | feature file removed | `has "ERROR E-ORPHAN"`, `RC=1` |
| removed properly | `adds` then a later `removes`, scenario file removed | no `E-ORPHAN` |
| removed in log, kept in features | `adds`, later `removes`, scenario still there | `has "WARN W-UNDECIDED"` |
| drift | scenario step reworded after the record | `has "WARN W-DRIFT"`, `RC=0` |
| drift acknowledged | add a `rewords` with the new fp | no `W-DRIFT` |
| superseded is not live | old decision `adds` a now-absent scenario and is superseded by a `changes` on a present scenario | no `E-ORPHAN` |
| conflict | two decisions both supersede `S-01` | `has "WARN W-CONFLICT"` |
| undecided | tagged scenario, empty log | `has "WARN W-UNDECIDED"` |
| legacy count | two untagged scenarios | `has "I-LEGACY 2"` |
| duplicate tag | id on two scenarios | `has "ERROR E-DUP-SCENARIO"` |
| exclude and defer | decision with only `excludes`, another with only `defers`, a third with no effects | `RC=0`, no findings |
| open resolved | `open` record then a decision with `resolves` | no finding. (The story page test in Task 6 checks the display.) |
| scope | git repo; story A has drift and is untouched; story B changes | with `--base HEAD`, no `W-DRIFT` for A. Without `--base`, `W-DRIFT` for A. |
| scope, deleted scenario | scenario deleted in the working tree, its decision untouched | with `--base HEAD`, `E-ORPHAN` still reported |

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: the new cases fail. The Task 1 and 2 cases still pass.

- [ ] **Step 3: Implement** the state function and the findings.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): live decisions and reconciliation findings"
```

---

### Task 5: Status derivation, `decisions.sh status`

**Files:**
- Modify: `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Consumes: `scan_scenarios` (feature tags per scenario, file path).
- Produces, CLI: `decisions.sh status ID --features F [--scope scenario|feature|directory] [--planned-tag T] [--manual-only-tag T] [--blocked-tag T] [--planned-dir N] [--manual-only-dir N]`. Prints one of `automated`, `planned`, `manual-only`, `blocked`. Exit 1 with `not found` when the scenario is absent. Defaults: scope `scenario`, planned tag `@pending`, manual-only tag `@manual-only`, no blocked tag. Env fallbacks `BDD_STATUS_SCOPE` and the like are not needed.
- Precedence when several markers apply: `manual-only`, then `blocked`, then `planned`, then `automated`.
- Scope `scenario` reads the scenario's own tags. Scope `feature` reads the `Feature:` tags. Scope `directory` matches a path component of the feature file, relative to `--features`, against `--planned-dir` or `--manual-only-dir`.
- Produces: a shared function `status_of ID` that Task 6 calls.

- [ ] **Step 1: Write the failing tests**

| Case | Setup | Assertions |
|---|---|---|
| default scenario scope | scenario with `@pending` | `planned` |
| automated | no marker | `automated` |
| manual only | `@manual-only` | `manual-only` |
| precedence | both `@pending` and `@manual-only` | `manual-only` |
| blocked | `--blocked-tag @blocked`, scenario has it | `blocked` |
| custom planned tag | `--planned-tag @manual`, scenario has `@manual` | `planned` |
| feature scope | tag on `Feature:`, none on the scenario | `planned` with `--scope feature` |
| directory scope | file under `features/formulated/`, `--planned-dir formulated` | `planned` |
| directory scope, nested | file under `features/manual/ldap/`, `--manual-only-dir manual` | `manual-only` |
| missing | unknown id | exit 1, `not found` |

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: the new cases fail.

- [ ] **Step 3: Implement** `status` and `status_of`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): scenario status derivation"
```

---

### Task 6: Story page, `decisions.sh show`

**Files:**
- Modify: `.claude/scripts/decisions.sh`, `tests/test_decisions.sh`

**Interfaces:**
- Consumes: state function (Task 4), `status_of` (Task 5), `--base`-style id listing at a ref (Task 2).
- Produces, CLI: `decisions.sh show STORY [--dir D] [--features F] [--since REF] [--channel URL]` plus the status flags from Task 5. Markdown on stdout, exit 0. An unknown story prints `No decisions recorded for STORY` and exits 0.
- Output layout, in order, empty sections omitted except "What we agreed":
  1. `# Agreed behavior: STORY`
  2. A blockquote banner: `> Generated from git at commit <short sha> (<commit date>). Read-only: do not discuss here.` The date is the commit date, so output is deterministic. Add ` (uncommitted changes)` when the tree is dirty. Outside git: `> Generated from files, not in a git repository. Read-only: do not discuss here.` With `--channel`: a second line `> Discussion: <url>`.
  3. `## Changed since you last looked` (only with `--since`): records whose ids are absent at REF. One line each, first matching rule wins: non-empty `supersedes` gives `Changed: <text> (was: <superseded text>)`; a `removes` effect gives `Removed:`; `excludes` gives `Left out:`; `defers` gives `Postponed:`; otherwise `Added:`.
  4. `## What we agreed`: live decisions that have a scenario effect, `- <text> (<status words>) ([source](ref))`. Status words, unique and in this order: `automated`, `planned`, `checked by hand`, `waiting on the product` (from `status_of`; a scenario that is absent adds nothing). When none: `- Nothing agreed yet.`
  5. `## Left out, postponed or accepted`: live decisions with `excludes`, `defers` or no effects.
  6. `## Still open`: open items.
  7. `## History`: superseded and closed decisions, `- <text> (replaced on <at>)` or `(closed)`.
- The source link is the first source with role `agreed`, else the first source. No link when there are no sources. The page never shows ids, fingerprints or `v`.

- [ ] **Step 1: Write the failing tests**

| Case | Setup | Assertions |
|---|---|---|
| section order | one agreed, one excluded, one open, one superseded | headings appear in the order above (check line numbers with `grep -n`) |
| banner in git | committed repo | `has "Generated from git at commit"` and the short sha |
| banner outside git | plain dir | `has "not in a git repository"` |
| deterministic | run twice | identical output |
| channel | `--channel https://x/c` | `has "Discussion: https://x/c"` |
| status words | scenarios `@pending`, `@manual-only` and plain, one decision each | `(planned)`, `(checked by hand)`, `(automated)` |
| open resolved | `open` then resolving decision | the text is absent from "Still open" |
| superseded in history | old and new decisions | old text only under "History" |
| since | git repo; a new record after the base commit that supersedes one | `has "Changed: "` with `(was: ` |
| since kinds | new `excludes`, `defers`, `removes` and plain records | `Left out:`, `Postponed:`, `Removed:`, `Added:` |
| hostile text | `text` is `A \| B *bold* "q" é 中` | the text appears verbatim in the output |
| source link | decision with an `agreed` source | `([source](` and the ref |
| no ids | any run | `lacks "S-01"` and `lacks "aaaaaaaa"` |
| unknown story | `show NOPE` | `has "No decisions recorded for NOPE"`, `RC=0` |
| empty sections | story with only an agreed item | `lacks "## Still open"` |

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_decisions.sh`
Expected: the new cases fail.

- [ ] **Step 3: Implement** `show`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/test_decisions.sh && bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude/scripts tests/test_decisions.sh
git commit -m "feat(log): story page"
```

---

### Task 7: The `bdd-reconcile` and `bdd-feedback` skills

**Files:**
- Create: `.claude/commands/bdd-reconcile.md`, `.claude/commands/bdd-feedback.md`
- Modify: `.claude/bdd-config.template.md` (roles only), `tests/test_skills.sh`

**Interfaces:**
- Consumes: the `decisions.sh` CLI from Tasks 1 to 6. Skills call `.claude/scripts/decisions.sh` and pass flags read from `bdd-config.md`.
- Produces: two skills with `description` and `allowed-tools` frontmatter, like the others. Roles `reconciler` (`bdd-reconcile`) and `feedback-intake` (`bdd-feedback`), both not required, in the template's Skill Roles table.

Content requirements:

`bdd-reconcile`:
- Reads `decision_log`, `decisions_dir`, `features_dir`, `scenario_id_prefix` and the status rows. If `decision_log` is not `on`, says the log is off and stops.
- Checks `jq` is available and says how to install it when it is not.
- Runs `decisions.sh check` with `--base` set to the merge base with the default branch when on a feature branch, and with no `--base` for `--all`.
- Judgment check: reads the live decisions and reports any two that contradict. Never edits anything.
- `--show STORY [--since REF] [--channel URL]` runs `decisions.sh show`.
- Audit mode re-derives scenarios from live decisions and reports differences as findings, never applies them.
- States that reconciliation is a report, not a sync. Explains the legacy count.

`bdd-feedback`:
- Input: a story key and pasted text. The builder labels each pasted block with its channel (Slack, Jira, PR). May fetch Jira comments through the configured `requirements-sync` skill.
- Steps as in the spec: read scenarios and live decisions; split into messages; classify each as approve, change, question or unclear; for a change propose a `.feature` edit that reuses existing steps and a record that supersedes or extends; compare with live decisions first and propose `confirms` for a match; record approvals as sources, or as `confirms` when the decision is already on the base branch; show everything; wait for the builder's approval per item; only then write.
- Rules: unclear never counts as approval; a question gets a drafted reply, no edit; conflicting channels block the record until the builder resolves it, and the record then keeps the objection as a source with role `objected`; a changed fingerprint prompts "rewording or behavior change?" and proposes `rewords` or `changes`; unanswered questions become `open` records; nothing is committed without being asked.
- Writing records: take `fp` from `decisions.sh fingerprint`; add the spec id tag to a legacy scenario the first time a decision touches it; run the `lint` row afterwards; run `decisions.sh check`.
- When `decision_log` is off, still classify and propose `.feature` edits, write no records, and say so.

- [ ] **Step 1: Write the failing tests** in `tests/test_skills.sh`

```bash
RC_="$ROOT/.claude/commands/bdd-reconcile.md"
FB="$ROOT/.claude/commands/bdd-feedback.md"
assert_file "$RC_"; assert_file "$FB"
for s in 'decisions.sh check' 'decisions.sh show' '--base' 'report, not a sync' 'never edits' 'contradict' 'audit' 'jq' 'legacy' 'decision_log'; do
  assert_contains "$RC_" "$s"
done
for s in 'approve' 'change' 'question' 'unclear' 'Unclear never counts as approval' 'confirms' 'supersedes' 'channel' 'writes nothing until' 'rewords' 'decisions.sh fingerprint' 'decision_log' 'Nothing is committed without being asked' 'objected' 'open'; do
  assert_contains "$FB" "$s"
done
for f in "$RC_" "$FB"; do assert_not_contains "$f" "$(printf '\xe2\x80\x94')"; done
for s in reconciler feedback-intake; do assert_contains "$CFG" "$s"; done
```

The existing role-to-file loop in `test_skills.sh` already checks that every `bdd-*` role in the template has a skill file.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_skills.sh`
Expected: failures for the missing files and roles.

- [ ] **Step 3: Write the two skills** and add the two roles to the template.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/run.sh`
Expected: `failed=0`.

- [ ] **Step 5: Commit**

```bash
git add .claude tests/test_skills.sh
git commit -m "feat(skills): bdd-reconcile and bdd-feedback"
```

---

### Task 8: Config rows, status vocabulary and log writing in design and implement

**Files:**
- Modify: `.claude/bdd-config.template.md`, `.claude/commands/bdd-design.md`, `.claude/commands/bdd-implement.md`, `tests/test_skills.sh`

**Interfaces:**
- Consumes: `decisions.sh fingerprint` (Task 3), the new skills (Task 7).
- Produces, config rows (template, with defaults): Conventions gain `decisions_dir` (`docs/decisions`), `scenario_id_prefix` (`spec-`), `status_scope` (`scenario`, or `feature` or `directory`), `manual_only_tag` (`@manual-only`), `blocked_tag` (empty), `planned_dir` and `manual_only_dir` (empty, used with directory scope). The `unautomated_tag` default changes from `@manual` to `@pending`. The Workflow table gains `decision_log` (`off`).

Behavior changes (keep every phrase `tests/test_skills.sh` already asserts, such as `unautomated tag`, `unautomated_tag`, `excluding the unautomated tag`, `Do this only after the verifier`; the existing negative assertion on `implement` stays):

`bdd-design`:
- Phase 3 or 4, scope `specify-only` and `specify-and-implement` alike: for each scenario that needs a human (a GUI-only client, a physical device, a manual runbook), propose the **manual_only_tag**. The builder confirms. Everything else is unautomated until implemented.
- Phase 5, `specify-only`: place the status marker where **status_scope** says (scenario tag, feature tag, or directory). With directory scope and a partly approved feature, say that automated scenarios live in the automated directory and the rest stay.
- When `decision_log` is `on` and the change passes the size gate: after approval, write a decision record for each approved scenario and exclusion, with `fp` from `decisions.sh fingerprint`; tag each scenario with `@<scenario_id_prefix><slug>`; run the `lint` row; run `decisions.sh check`. Add the output of `decisions.sh show` as a **Decisions** section of the spec summary. When the log is off, none of this happens.
- Update the default in the text that mentions `@manual`. Keep the anti-pattern row about manual scenarios, reworded for the planned marker.

`bdd-implement`:
- Work on scenarios that carry the planned marker. Never edit or implement a scenario carrying the **manual_only_tag**; report that it stays manual.
- Phase 3: after the verifier passes, remove the planned marker as today and add **automated_tag** if set. Update the default from `@manual` to `@pending` in the sentence. Never touch spec id tags.
- If implementing changes a scenario's text, say that the fingerprint will drift and that a `rewords` record is needed when the log is on.

- [ ] **Step 1: Write the failing tests**

```bash
for k in decisions_dir scenario_id_prefix status_scope manual_only_tag blocked_tag planned_dir manual_only_dir decision_log; do
  assert_contains "$CFG" "$k"
done
assert_contains "$CFG" '| unautomated_tag | `@pending`'
assert_not_contains "$CFG" '| unautomated_tag | `@manual`'
for s in 'manual_only_tag' 'status_scope' 'decision_log' 'decisions.sh fingerprint' 'scenario_id_prefix' 'size gate' 'Decisions' 'decisions.sh check'; do
  assert_contains "$G" "$s"
done
for s in 'manual_only_tag' 'stays manual' 'fingerprint' 'rewords' 'default `@pending`'; do
  assert_contains "$I" "$s"
done
assert_not_contains "$I" 'default `@manual`'
assert_not_contains "$G" 'default `@manual`'
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/test_skills.sh`
Expected: failures on the new assertions only.

- [ ] **Step 3: Edit the template and the two skills** as described. Edit only the named sections.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/run.sh`
Expected: `failed=0`, including every earlier skill assertion.

- [ ] **Step 5: Commit**

```bash
git add .claude tests/test_skills.sh
git commit -m "feat(skills): status vocabulary and decision log writing"
```

---

### Task 9: Installer, README and dry run

**Files:**
- Modify: `install.sh`, `README.md`, `tests/test_install.sh`, `tests/test_skills.sh`
- Create: `docs/superpowers/dry-runs/<date>-feedback-and-reconcile.md`, `tests/fixtures/feedback.txt`

**Interfaces:**
- Consumes: all earlier tasks.
- Produces, installer: copies `.claude/scripts/decisions.sh` to `<target>/.claude/scripts/decisions.sh` (executable) and the schema to `<target>/.claude/schemas/decision.schema.json`; installs `bdd-feedback` and `bdd-reconcile` with the source header like the other skills; `report_missing_row` notes for `decision_log` (`off`), `decisions_dir` (`docs/decisions`), `scenario_id_prefix` (`spec-`), `status_scope` (`scenario`), `manual_only_tag` (`@manual-only`), `blocked_tag` (`none`), `reconciler` and `feedback-intake`; the `unautomated_tag` note now says the default is `@pending` (v1 default was `@manual`); the next-steps text prints the `.gitattributes` line `docs/decisions/*.jsonl merge=union` and says the log needs `jq`. It never edits the project's `.gitattributes`.
- Produces, README: sections for the decision log (opt-in), feedback intake, the story page and `jq`; the Modes section and the optional-rows table say `@pending`; the architecture diagram lists the two new skills.

- [ ] **Step 1: Write the failing tests**

`tests/test_install.sh`, on a fresh install into `$T/fresh`:

```bash
assert_file "$T/fresh/.claude/commands/bdd-feedback.md"
assert_file "$T/fresh/.claude/commands/bdd-reconcile.md"
assert_file "$T/fresh/.claude/schemas/decision.schema.json"
[ -x "$T/fresh/.claude/scripts/decisions.sh" ] && pass || fail "decisions.sh not executable"
assert_contains "$T/fresh-out.txt" "merge=union"
```

On the old-config install (`$T/old`): `assert_contains "$T/old-out.txt"` each of `decision_log`, `decisions_dir`, `scenario_id_prefix`, `status_scope`, `manual_only_tag`, `blocked_tag`, `'@pending'`. A second run leaves the config byte-identical (the existing test covers it).

Also run the installed script once: `bash "$T/fresh/.claude/scripts/decisions.sh" check` in an empty project exits 0 and prints `I-EMPTY`. This proves the schema path resolves after install.

`tests/test_skills.sh`: README assertions `'decision log'`, `'bdd-feedback'`, `'bdd-reconcile'`, `'jq'`, `'@pending'`, `'story page'`; `assert_not_contains "$R" 'tagged `@manual`'`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bash tests/run.sh`
Expected: failures on the new assertions only.

- [ ] **Step 3: Implement** the installer and README changes.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bash tests/run.sh`
Expected: `failed=0` in all three suites.

- [ ] **Step 5: Dry run in a scratch project**

Install into a scratch directory (`mktemp -d`). Create two features and a fixture `tests/fixtures/feedback.txt` with pasted Slack and Jira lines that contain one approval, one change, one question and one ambiguous reply ("looks fine, but what about refunds?"). Set `decision_log` to `on`. Run headless:

```bash
claude -p "/bdd-feedback PROJ-1 $(cat tests/fixtures/feedback.txt)" --allowedTools "Read,Bash,Grep,Glob"
```

Expected: a classification of all four messages, the ambiguous one marked unclear and not counted as approval, proposed edits and records, no `.jsonl` file written before approval. Then write one record by hand, change a scenario's wording, and run `/bdd-reconcile`. Expected: a `W-DRIFT` finding and a plain statement that nothing was edited. Run `/bdd-reconcile --show PROJ-1` and check the page.

Record the commands, the expected results and an excerpt of each output in `docs/superpowers/dry-runs/<date>-feedback-and-reconcile.md` (date from `date +%F`). If a run differs from expectation, stop and report it. Do not work around it.

- [ ] **Step 6: Commit**

```bash
git add install.sh README.md tests docs/superpowers/dry-runs
git commit -m "feat: installer, README and dry run for the decision log"
```

---

## Self-review

- **Spec coverage:** record kinds and fields (Task 1); schema versioning (Task 1); sources and `confirms` (Tasks 1 and 7); immutability (Task 2); fingerprint (Task 3); live decisions, findings, scope (Task 4); status vocabulary and the three scopes (Task 5); story page (Task 6); the two skills (Task 7); config rows, planned-marker default, manual-only handling, log writing, size gate (Task 8); installer, merge advice, `jq` note, README (Task 9). The union-merge claim is tested in Task 2. The trivial-change skip is the existing size gate, referenced in Task 8.
- **Names:** `decisions.sh`, subcommands `check`, `fingerprint`, `status`, `show`; codes `E-JSON`, `E-SCHEMA`, `E-VERSION`, `E-DUP-ID`, `E-REF`, `E-APPEND`, `E-DUP-SCENARIO`, `E-ORPHAN`, `W-DRIFT`, `W-UNDECIDED`, `W-CONFLICT`, `I-LEGACY`, `I-EMPTY`. Used the same way in every task.
- **Known limit:** the first valid-log tests in Task 1 include the scenario file so the Task 4 orphan check does not break them.

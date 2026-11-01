# godrose/bdd: decision log and feedback intake

Status: DRAFT for review. Items marked **[decided]** come from the author. Items marked **[my call]** are the designer's guesses and need confirming.

Builds on `2026-10-24-bdd-methodology-design.md`. Read that first.

## Intent

The v1 skills cover the builder's side: discover, design, implement, verify. They do not cover the people around the builder. Product managers (PMs) give feedback in Slack, in Jira comments and in pull requests. Nothing collects it, and nothing turns it into a change to the specification. **[decided]**

This work adds two things. First, a **decision log**: an append-only record of what was agreed, by whom and why, kept in git. Second, **`bdd-feedback`**: a skill that takes pasted discussion text and proposes changes to the scenarios and the log. **[decided: these two come first]**

## Context

- The Jira plugin AssertThat shows scenarios inside the story and runs manual test runs. It has no version control and no vocabulary gate. **[decided]**
- Sync stays one way: repo to Jira. Two-way sync breaks the process. **[decided]**
- AssertThat allows one linked feature file per Jira issue.- PMs work in Slack and Jira, not in pull requests. They approve informally ("looks good", a thumbs-up). A PR approval is the formal gate. **[decided]**
- Feedback is scattered across three places today: PR, Jira comment, Slack. **[decided]**
- Each story gets a dedicated Slack channel. The agent has no Slack connector. The builder copies text in and out. **[decided: good enough for now]**
- Developers test their own features, using the scenarios and AssertThat test runs. There is no formal QA. The PM owns acceptance. **[decided]**

## The model

Two records of the same history, each with one job.

| Record | Job | Source of truth for |
|---|---|---|
| `.feature` files | Executable, readable behavior at any commit | What the system does |
| Decision log | Append-only record of intent | Why, who agreed, what was excluded |

Git already holds the changesets. A diff says what changed. It does not say what was decided. Three kinds of decision never appear in a diff: exclusions, rationale and source, and decisions that touch many scenarios. The log carries those. **[decided]**

The `.feature` files are **not** computed from the log. A compiler from decisions to Gherkin was considered and rejected. It would need structured decisions, step resolution by id, merge rules and versioned schemas. It would also constrain the discussion instead of helping it. **[decided]** A mechanical check keeps the two consistent instead.

## Goals

- Record every agreed decision in git, append-only, with its source. **[decided]**
- Turn pasted feedback from any channel into proposed edits, without ever applying one silently. **[decided]**
- Keep exactly one record of decisions. Slack, Jira and chat are inputs. Git is the record. **[decided]**
- Make drift between the log and the `.feature` files detectable. **[my call]**
- Keep each decision's text a plain sentence that a PM can read, in the generated views as well as in the file. **[decided]**

## Non-goals

- Computing the `.feature` files from the log. **[decided]**
- A Slack or Jira connector. Copy and paste is the transport for now. **[decided]**
- Two-way sync with any tracker. **[decided]**
- The acceptance digest, the channel naming convention and the opening post. They come after this release. **[decided: second priority]**
- A runner, framework or CLI of our own. **[my call]**

## Anti-goals

- A rigid format that shapes the discussion to fit the tooling. **[decided]**
- Two sources of truth that can disagree without anyone noticing.
- An unclear reply ("looks fine, but what about refunds?") counted as approval.
- A log nobody reads, written to satisfy a process. The skills write it, the builder approves it.
- Edits that reach a `.feature` file without a reviewed pull request.

## Components

### Decision log **[my call throughout, unless marked]**

**Format.** JSON Lines in git. One file per story, one JSON object per line, one record per object. The default directory is `docs/decisions/`, set by a `decisions_dir` config row. The file is named `<story>.jsonl`, for example `PROJ-123.jsonl`. Decisions that belong to no story go in `_project.jsonl`. A `.gitattributes` line, `docs/decisions/*.jsonl merge=union`, lets parallel branches append to one file without a merge conflict.

**Why JSON Lines and not one markdown file per decision.** Skills and the check script read the records far more than people do, and a decision is one sentence. Structured lines can be validated against a schema, queried and extended with new fields. A story's whole history sits in one file. The append-only rule becomes a line-level check: the earlier lines must be unchanged. Markdown files diff better for a human reader. That cost is accepted, because the pull request view is the generated spec summary, and `decisions.sh show` renders the records as a story page (see Story view).

**A decision record.** Shown pretty-printed here. In the file each record is a single line.

```json
{
  "v": 1,
  "id": "PROJ-123-03",
  "kind": "decision",
  "story": "PROJ-123",
  "at": "2026-10-31",
  "text": "An empty order list exports a file with the header row only.",
  "why": "Accountants import the file into a spreadsheet.",
  "effects": [{"op": "adds", "scenario": "spec-export-empty-list", "fp": "3f9a1c2e"}],
  "supersedes": ["PROJ-123-01"],
  "decided_by": ["PM", "builder"],
  "sources": [
    {"kind": "slack", "ref": "https://example.slack.com/archives/C123/p456",
     "role": "agreed", "by": "PM", "quote": "yes, header only"}
  ]
}
```

Fields:

- `v` is the schema version. `id` is `<story>-<nn>`, numbered per story. A global counter would collide across branches. `at` is the date. `text` is one sentence of intent. `why` is optional.
- `effects` is a list that may be empty. Each effect has an `op`:
  - `adds`, `changes`, `rewords` or `removes` name a `scenario` id. The first three also carry `fp`, the fingerprint (see Reconciliation).
  - `excludes` and `defers` carry a short phrase and no scenario. `defers` means "decided in principle, no scenario yet", or "known issue, fix postponed", with the reason.
  - A decision with no effects records a rationale or an accepted risk.
- `supersedes` lists earlier record ids. `resolves` lists the ids of `open` records that this decision answers.
- There is no `status` field. The status is computed.
- `decided_by` uses roles or names as written in the discussion.

A decision is **live** when no later record supersedes it and at least one of its effects still stands. A decision whose scenarios were all removed by later records is closed.

**Confirmations.** A second record kind carries later evidence for an existing decision:

```json
{"v": 1, "id": "PROJ-123-07", "kind": "confirms", "of": "PROJ-123-03", "at": "2026-11-02",
 "sources": [{"kind": "jira", "ref": "https://example.atlassian.net/browse/PROJ-123?focusedCommentId=1",
              "role": "agreed", "by": "PM", "quote": "approved"}]}
```

**Open items.** A third record kind holds a question or an objection that has no answer yet:

```json
{"v": 1, "id": "PROJ-123-08", "kind": "open", "story": "PROJ-123", "at": "2026-10-30",
 "text": "Is the customer name exported as one column or two?",
 "sources": [{"kind": "slack", "ref": "https://example.slack.com/archives/C123/p789",
              "role": "proposed", "by": "builder", "quote": "one column or two?"}]}
```

An `open` record is still open until a later decision lists its id in `resolves`. The story view shows the open ones under "Still open".

**Sources.**

- A decision may have many sources. Each source has a `kind` (`slack`, `jira`, `pr`, `meeting` or `other`), a `ref` link, a `role` (`proposed`, `agreed` or `objected`), `by` and a short `quote`.
- One decision discussed in several channels is one record with several sources. `bdd-feedback` takes messages from several channels in one run, each pasted under a channel label.
- Evidence that arrives after a record is on the base branch is a `confirms` record. It is never an edit.
- Before it writes a new decision, `bdd-feedback` compares it with the live decisions. A match produces a `confirms` proposal, not a duplicate.
- Conflicting sources, such as yes in one channel and no in another, block the decision. The builder resolves the conflict. The record then cites the resolving message as `agreed` and keeps the earlier objection as `objected`, so the history shows both.
- Sources are references. The log stores links and short quotes, never whole threads.

**Immutability.** Records on the base branch are never edited or deleted. A mistake or a change of mind is a new record that supersedes the old one. Inside an open pull request a record can still be edited. A proposal waits there until the approving message arrives, and the record is final when the PR merges.

**Schema changes.**

- Every record carries `v`. The schema ships with the skills as `decision.schema.json`. `decisions.sh` validates each line against the schema of its declared `v`.
- Adding an optional field needs no new version.
- Renaming or removing a field, or changing what a field means, gets a new `v`. Readers support every version and convert old records to the current shape in memory. Old lines are never rewritten, so the append-only rule has no exceptions.
- A record with a `v` newer than the installed skills know is a hard error that says to update the skills.
- A change to the record format is listed in the release notes of the skills.

**Scenario identity.** Each scenario in the log carries a stable tag, default prefix `spec-`, for example `@spec-export-empty-list`. Ids never change. A poor slug is cosmetic. The tag survives renames and file moves. A tracker key is not unique per scenario, so it cannot do this job (one story has many scenarios). The prefix is a config row. The default uses a hyphen because some tag lints allow only lowercase letters, digits and hyphens.

Tag families are checked by the project's own lint. After writing tags, the skills run the `lint` row and report a new tag family that must be registered first (some projects require every tag to be registered in a list).

`bdd-reconcile` finds scenarios by tag across every directory. A scenario that moves from a `formulated/` folder to an `automated/` folder, or a file that is split, stays linked to its decision.

`decisions_dir` must not sit inside a directory that a sync or generator rewrites.

### Reconciliation check

**Reconciliation is a report, not a sync.** Nothing flows from the log into the `.feature` files, or back, on its own. Changes happen only through proposals that the builder approves in a pull request. **[decided: the spec is not computed from the log]**

`bdd-reconcile` runs on demand. The mechanical checks are also in a small shell script, `decisions.sh`, for a pre-push hook or CI. The script has the subcommands `check`, `fingerprint`, `status` and `show`, and needs `jq`. **[decided: a script is fine]**

**Fingerprint.** `fp` is a short hash of a scenario's normalized content: name, steps, tables and examples. It ignores comments, whitespace, and status, suite and area tags. The script computes it. A decision that adds, changes or rewords a scenario records the fingerprint at that moment. The script recomputes it from the current file and compares.

**When the product evolves.**

| Event | What reconcile sees | What the builder records |
|---|---|---|
| Scenario reworded, same behavior | fingerprint differs from the last decision | `rewords`: one line, and it may list many scenarios |
| Behavior changes | fingerprint differs | `changes`, which supersedes the older decision |
| Scenario deleted | a live decision points at a missing id | `removes` |
| Scenario split or merged | old ids missing, new ids with no decision | one decision with `removes` and `adds` |
| File moved, folder renamed, status tag flipped | nothing: ids are tags and the fingerprint ignores status | nothing |
| Step library renamed everywhere | many fingerprints differ | one `rewords` listing them |
| Two branches change the same scenario | two live decisions supersede the same record | a third record that supersedes both |
| Product changes and a scenario goes red | nothing: reconcile does not run tests | fix the product, or record a `changes` |

**Findings.**

- **Errors** block a pull request: an unreadable or schema-invalid record, an unknown `v`, a duplicate id, an existing record edited or deleted, a scenario removed without a covering `removes`, a live decision that points at a missing scenario, and a spec id that tags more than one scenario.
- **Warnings:** a fingerprint that differs from the last decision, two live decisions that supersede the same record, and a spec-tagged scenario with no live decision.
- **Info:** the status table (see Items not yet implemented) and the count of scenarios without a spec tag, reported as "legacy, not tracked".

Scenarios without a spec tag are not checked. `bdd-feedback` gives a legacy scenario an id the first time a decision touches it, so existing projects adopt the log gradually and need no backfill.

**Scope.** Findings are computed for the stories whose log file or scenarios the diff touches. Older debt elsewhere does not block a pull request. `bdd-reconcile --all` audits everything.

**History.** The log lives in git. "The decisions in force at commit C" is the log files at C.

Judgment check (done by the agent):

- No two live decisions contradict each other. A new decision that conflicts with a live one must supersede it.

Audit mode: the agent re-derives scenarios from the live decisions and diffs them against the real `.feature` files. Differences are reported as findings and never applied.

### Story view **[decided]**

The log is storage. People read a generated story page. `decisions.sh show <story>` prints it as Markdown. GitHub renders Markdown in a pull request, and it pastes into Jira, Confluence or Slack as plain text. HTML is a later addition.

Sections, in order:

- **Banner.** Generated from git at a commit and date. Read-only. Discussion lives in the story's channel, with a link.
- **Changed since you last looked.** Shown only when a starting commit is given. One line for each new record: Added, Changed (with what it replaced), Removed, Left out or Postponed.
- **What we agreed.** Live decisions that have scenarios, in plain words, each with a status word: automated, planned, checked by hand or waiting on the product.
- **Left out, postponed or accepted.** Live decisions with `excludes`, `defers` or no effects.
- **Still open.** `open` records that no decision resolves.
- **History.** Superseded and closed decisions, last.

Rules:

- The view is generated and read-only. It is never an input to the log.
- It shows no ids, fingerprints or schema versions. Each item links to its source.
- Output is deterministic for the same log and features, and it is stamped, so a pasted copy shows its age.
- Publishing to Jira or Confluence is by hand in v1. The builder pastes the page.

### `bdd-feedback`

Input: a story key and pasted discussion text. The text may come from a Slack channel, Jira comments or PR comments. If the `requirements-sync` role is configured and can read comments, the skill may fetch Jira comments itself. **[my call]**

Steps:

1. Read the story's `.feature` files and live decisions.
2. Split the pasted text into messages. The builder labels each pasted block with its channel (Slack, Jira, PR). Classify each message as **approve**, **change**, **question** or **unclear**.
3. For each **change**, propose a `.feature` edit that reuses existing steps, and a decision record that supersedes or extends an earlier one. Compare it with the live decisions first. If it matches one, propose a `confirms` record instead of a duplicate.
4. For each **approve**, record who agreed, as a source on the decision, or as a `confirms` record if the decision is already on the base branch. **Unclear never counts as approval.**
5. Show the classification, the proposed edits and the proposed records. List every message it could not map.
6. The builder approves each item. Only then does the skill write files. The edits go into the pull request. Nothing is committed without being asked.

Rules:

- Step reuse is a hard rule, as in every other skill.
- A question gets no edit. The skill drafts a reply for the builder to paste back.
- If a proposed decision conflicts with a live one, the skill says so and requires a `supersedes`.
- If messages from different channels disagree, the skill shows both and writes nothing until the builder resolves it.
- When a scenario's fingerprint has changed, the skill asks whether it was a rewording or a change of behavior, and proposes `rewords` or `changes`.

### Items not yet implemented **[my call]**

"Not yet implemented" covers four different states. Unautomated work is a normal state of a project, not an exception.

| State | Example | How projects mark it |
|---|---|---|
| Decided and specified, meant to be automated later | a planned scenario | `@pending` (template default), `@manual` in some projects, or a `formulated/` folder |
| Specified and automated, product not built | a scenario written ahead of the feature | project-specific, set with `blocked_tag` |
| Manual by design | a GUI-only client | `@manual-only`, or a `manual/` folder |
| Decided, no scenario yet, or fix postponed | "defer until product asks" | nothing, or `@known-issue` |

Rules:

- **Status never goes into a decision record.** Records are immutable and status changes often. Status stays in tags and folders and is derived.
- **`bdd-reconcile` reports status and never fails on it.** For each live decision it shows the scenario and its state: automated, planned, pending, manual by design, or no scenario. A pending scenario under a live decision is healthy.
- **A new effect type, `defers`.** It records "decided in principle, no scenario yet", or "known issue, fix postponed", with a reason. A later record that `adds` the scenario and supersedes the earlier one replaces it.
- **A decision with no effect is allowed.** It records an accepted risk or a rationale and nothing else.
- **Status vocabulary is config.** Rows name the tag or folder for each state, and say where status lives: on each scenario, on the feature, or by directory. Some projects mark status on each scenario. Others forbid a status tag on a scenario and keep it on the feature or in a folder.
- **The template tells "planned" apart from "manual by design". [decided]** Some end-to-end tests cannot be automated and stay manual for good. Pending means meant to be automated at some point.
  - `unautomated_tag` is the planned marker. Its default changes from v1's `@manual` to `@pending`. A project that already sets the row keeps its value. For projects without the row, the installer prints a note about the new default. **[my call]**
  - `manual_only_tag` is the by-design marker, default `@manual-only`.
  - `blocked_tag` is optional and has no default. A project that wants a third state for "automated, red until the product ships" sets it.
- **Skills treat the two markers differently.**
  - `bdd-design` proposes `@manual-only` when a scenario needs a human, for example a GUI-only client. The builder confirms. Everything else is `@pending`.
  - `bdd-implement` works on `@pending` scenarios and never touches `@manual-only` ones.
  - `bdd-run` and code generation exclude both. Undefined steps under either marker are expected and never an error.
  - Manual-only scenarios are still run by the builder, as manual test runs in the tracker. They are never counted as automation debt.

### Changes to existing skills **[my call]**

- `bdd-design` writes decision records, with fingerprints, for every approved scenario and exclusion, and tags scenarios with their ids. The spec summary stays as the pull request view. It is generated from the records and links to them.
- `bdd-implement` keeps spec tags intact when it automates a scenario.
- `bdd-design` and `bdd-implement` read where status lives (scenario tag, feature tag or directory) instead of always tagging each scenario. In v1 they tag per scenario, which some project lints reject. With directory status, partial automation splits a file: the automated scenarios move to the automated folder, the rest stay.
- `bdd-implement` removes the "planned" marker after a pass. It never does so for a scenario marked manual by design.
- `bdd-config.template.md` gains `decision_log` (`on` or `off`), `decisions_dir`, `scenario_id_prefix`, `status_scope` (`scenario`, `feature` or `directory`), `manual_only_tag` and `blocked_tag`. Absent rows mean the log is off, the directory is `docs/decisions`, the prefix is `spec-`, status is per scenario, the planned marker `@pending` and the manual-only marker `@manual-only`.
- `install.sh` installs the new skills, `decision.schema.json` and `decisions.sh`, and reports the new rows when they are missing. It prints the `.gitattributes` line for the log and does not edit the file. **[my call]**
- Trivial changes skip the log. The existing size gate decides. **[my call]**

## Constraints

- Claude Code skills only. **[decided]**
- Existing users update by re-running `install.sh` without losing `bdd-config.md`. **[my call]**
- With the log off, behavior is identical to v1. **[my call]**
- The log tooling needs `jq`. With the log off, `jq` is not needed. **[my call]**
- No em-dashes in generated text. Short, simple sentences. **[author's style rule]**

## Left to the builder

- Exact skill wording and the layout of the `bdd-feedback` output.
- The normalization rules for the fingerprint, and the portable hash command the script uses.
- Where `decision.schema.json` and `decisions.sh` are installed.
- The classification heuristics for the four message types.
- Whether the spec summary is regenerated or kept in step with the records.
- How `bdd-reconcile` finds the base branch for the append-only check.

## Decided in review

- A small shell script for the mechanical checks is acceptable. **[decided]**
- The log defaults to off. The individual builder sees no change from v1 until they opt in. **[decided]**
- Short quotes and roles or names from the discussion may be committed to git. **[decided]**
- The template tells "planned to automate" (`@pending`) apart from "manual by design" (`@manual-only`). Manual-only tests stay manual for good. **[decided]**

- JSON Lines, one file per story, is the storage format. A generated story page is the reading format for non-technical readers. **[decided]**
- The fingerprint warning is the right amount of friction. **[decided]**

## Open questions for the author

None.

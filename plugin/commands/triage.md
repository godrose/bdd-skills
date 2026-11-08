---
description: "Turn pasted discussion (Slack, Jira, PR comments) into proposed scenario edits and decision records, then write them only after approval"
allowed-tools: ["Agent", "Bash", "Read", "Edit", "Write", "Grep", "Glob", "AskUserQuestion"]
---

## BDD Triage

Take the discussion about a story and turn it into reviewed changes: scenario edits and decision records. The discussion lives in the story's channel. This skill reads it as pasted text and proposes. It writes nothing until the builder approves each item.

**Before starting**, read `.claude/bdd-config.md`. Read these rows: `decision_log`, `decisions_dir` (default `docs/decisions`), `features_dir`, `scenario_id_prefix` (default `spec-`), `lint`, the status rows, and the `requirements-sync` role. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

### Input

- A story key, for example `PROJ-123`.
- Pasted text. The builder labels each pasted block with its channel: Slack, Jira or PR. Several channels can come in one run.
- If the `requirements-sync` skill is configured and can read comments, you may fetch the Jira comments yourself.

> Plugin note: the script path in the commands below is an absolute path inside the plugin. If it still starts with `$`, or the script is not found, say the plugin root was not set, and stop. Do not search for the script elsewhere.

### Steps

1. **Read the current state.** Read the story's `.feature` files. If `decision_log` is `on`, run `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh show STORY` to see the live decisions.

2. **Split and classify.** Split the pasted text into messages. Classify each as:
   - **approve**: any positive reply counts. There is no single pattern.
   - **change**: someone wants different behavior.
   - **question**: someone asks something.
   - **unclear**: you cannot tell. **Unclear never counts as approval.**

3. **Propose.**
   - For a **change**, propose a `.feature` edit that reuses existing steps (a hard rule, as in every other skill) and a decision record that supersedes or extends an earlier one. Compare with the live decisions first. If the change matches one, propose a `confirms` record instead of a duplicate.
   - For an **approve**, record who agreed as a source on the decision. If the decision is already on the base branch, propose a `confirms` record instead of an edit.
   - For a **question**, draft a reply for the builder to paste back. No edit. If it stays unanswered, propose an `open` record.
   - List every message you could not map.

4. **Show everything**: the classification, the proposed edits and the proposed records.

5. **Wait.** The skill writes nothing until the builder approves each item. Ask per item.

6. **Write the approved items.**
   - Take `fp` from `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh fingerprint <spec-id> --features <features_dir>`. Compute it after the scenario is written.
   - Add the spec id tag (`@<scenario_id_prefix><slug>`) to a legacy scenario the first time a decision touches it.
   - Append records to `<decisions_dir>/<story>.jsonl`, one JSON object per line. Never edit an existing line.
   - Run the `lint` row when it is set. Report a new tag family that must be registered.
   - Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh check` and show the result.
   - Nothing is committed without being asked.

### Record shapes

- `decision`: `v`, `id` (`<story>-<nn>`), `kind`, `story`, `at`, `text`, optional `why`, `effects`, `supersedes`, `resolves`, `sources`.
- `confirms`: `v`, `id`, `kind`, `of`, `at`, `sources`.
- `open`: `v`, `id`, `kind`, `story`, `at`, `text`, `sources`.
- Effects are objects with an `op` field: `{"op":"adds","scenario":"spec-x","fp":"3f9a1c2e"}`. `adds`, `changes` and `rewords` carry `scenario` and `fp`. `removes` carries `scenario`. `excludes` and `defers` carry `phrase`.
- Sources are objects with `kind` (`slack`, `jira`, `pr`, `meeting` or `other`), `ref` (a link), `role` (`proposed`, `agreed` or `objected`), `by` and a short `quote`. Never store whole threads.
- `at` is a date, `YYYY-MM-DD`. Use `YYYY-MM-DD`, not a timestamp.

Example, one line in the file:

```
{"v":1,"id":"PROJ-1-01","kind":"decision","story":"PROJ-1","at":"2026-11-01","text":"An empty order list exports the header row only.","effects":[{"op":"adds","scenario":"spec-export-empty-list","fp":"3f9a1c2e"}],"sources":[{"kind":"slack","ref":"https://example.slack.com/archives/C1/p1","role":"agreed","by":"PM","quote":"Header row only, yes"}]}
```

### Rules

- Conflicting channels block the record. If one channel says yes and another says no, show both and write nothing for it until the builder resolves it. The record then cites the resolving message as `agreed` and keeps the earlier objection as a source with role `objected`.
- If a proposed decision conflicts with a live one, say so and require `supersedes`.
- When a scenario's fingerprint has changed since its last decision, ask: "rewording or behavior change?" Propose `rewords` for a rewording and `changes` for a change of behavior.
- When `decision_log` is not `on`, still classify and propose `.feature` edits. Write no records, and say the log is off.
- Short quotes and names may be committed. Do not store whole threads.

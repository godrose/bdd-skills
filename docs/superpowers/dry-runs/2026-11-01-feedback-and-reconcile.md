# Dry run: bdd-feedback and bdd-reconcile (2026-11-01)

Scratch project made with `install.sh`. Two feature files: `export.feature` (two spec-tagged scenarios) and `refund.feature` (one legacy scenario). Config: `decision_log` `on`, `workflow_mode` `specify-only`. Fixture: `tests/fixtures/feedback.txt` (one approval, one change, one question, one ambiguous reply, one bare "ok").

## 1. Feedback intake

Command:

```
claude -p "/bdd-feedback PROJ-1 $(cat tests/fixtures/feedback.txt)" --allowedTools "Read,Bash,Grep,Glob"
```

Expected: all messages classified, the ambiguous ones marked unclear and not counted as approval, edits and records proposed, no `.jsonl` written before approval.

Result, run 1: as expected on classification and on writing nothing. One defect: the proposed records did not follow the schema (effects as `{"adds": "spec-x"}`, sources with `who` and `channel`, `at` as a timestamp).

Fix: `bdd-feedback` now carries the exact effect and source shapes and a one-line example (test-first in `tests/test_skills.sh`).

Result, run 2 (after the fix, with one live decision in the log): the record for the approved message is a `confirms` of the live decision, not a duplicate. The change is a `decision` with `{"op":"changes",...}`. The questions are `open` records. "ok" and "looks fine, but what about refunds?" are unclear. The log file still had one line afterwards.

Excerpt:

```
**A. Confirm PROJ-1-01 (message 1).** This matches the live decision, so I propose a `confirms` record, not a duplicate.
{"v":1,"id":"PROJ-1-02","kind":"confirms","of":"PROJ-1-01","at":"2026-11-01", ...}
| 5 | Jira | Reviewer: "ok" | unclear. It names no decision, so it counts as nothing. |
```

## 2. Reconcile after a wording change

One record written by hand (with `fp` from `decisions.sh fingerprint`). Then the last step of `spec-export-empty-list` was reworded.

Command: `claude -p "/bdd-reconcile --all" --allowedTools "Read,Bash,Grep,Glob"`

Expected: a `W-DRIFT` finding and a plain statement that nothing was edited.

Result: as expected.

```
I ran `decisions.sh check` with no `--base`. It found 0 errors and 2 warnings. I did not edit anything.
- W-DRIFT at features/export.feature:3: spec-export-empty-list changed since decision PROJ-1-01.
- W-UNDECIDED at features/export.feature:9: spec-export-limit has no live decision.
- I-LEGACY: 1 scenario has no spec tag ... legacy and not tracked.
```

## 3. Story page

Command: `claude -p "/bdd-reconcile --show PROJ-1" --allowedTools "Read,Bash,Grep,Glob"`

Expected: the generated page, banner and status word, no files changed.

Result: as expected after one correction. The first call used a wrong flag name and printed the usage text. The skill now lists the config row to flag mapping (test-first).

```
# Agreed behavior: PROJ-1
> Generated from git at commit 8d4ef3b (2026-11-01) (uncommitted changes). Read-only: do not discuss here.
## What we agreed
- An empty order list exports the header row only. (automated) ([source](https://example.slack.com/archives/C1/p1))
```

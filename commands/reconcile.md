---
description: "Check the decision log against the scenarios: find orphans, drift, undecided scenarios and contradictions. Reports only, never edits."
allowed-tools: ["Bash", "Read", "Grep", "Glob"]
---

## BDD Reconcile

Compare the decision log with the real `.feature` files and report what does not line up. **Reconciliation is a report, not a sync.** Nothing flows from the log into the scenarios, or back. This skill never edits a file. Changes happen only through proposals the builder approves, for example from `bdd:feedback`.

**Before starting**, read `.claude/bdd-config.md`. Read these rows: `decision_log`, `decisions_dir` (default `docs/decisions`), `features_dir`, `scenario_id_prefix` (default `spec-`), and the status rows (`unautomated_tag`, `manual_only_tag`, `blocked_tag`, `status_scope`, `planned_dir`, `manual_only_dir`) when present. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

If `decision_log` is not `on`, say the decision log is off for this project and stop.

### Prerequisites

The script needs `jq`. Run `command -v jq`. If it is missing, say so and give an install hint (for example `brew install jq`), then stop.

### Input

- No argument: check the change on the current branch.
- `--all`: audit everything, with no `--base`.
- `--show STORY [--since REF] [--channel URL]`: print the story page.

> Plugin note: the script path in the commands below is an absolute path inside the plugin. If it still starts with `$`, or the script is not found, say the plugin root was not set, and stop. Do not search for the script elsewhere.

### Steps

1. **Mechanical check.** Run:

   ```
   "${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh check --dir <decisions_dir> --features <features_dir> --prefix <scenario_id_prefix> --base <ref>
   ```

   On a feature branch, `<ref>` is the merge base with the default branch (`git merge-base <default-branch> HEAD`). With `--all`, leave out `--base`. Show the findings as printed.

2. **Explain the findings.** Group them by level. Errors block a pull request. Warnings need a decision from the builder. Info is context.

   | Code | Meaning |
   |------|---------|
   | `E-JSON` | A line in a log file is not valid JSON. |
   | `E-SCHEMA` | A record misses a required field or has a bad value. |
   | `E-VERSION` | A record has a newer `v` than the installed skills know. Update the skills. |
   | `E-DUP-ID` | Two records share an id. |
   | `E-REF` | A record points at an id that does not exist. |
   | `E-ORPHAN` | A live decision points at a scenario that is gone. Restore it or record a `removes`. |
   | `E-APPEND` | An earlier record was edited or deleted. Records are append-only. |
   | `E-DUP-SCENARIO` | One spec id tags more than one scenario. |
   | `W-DRIFT` | A scenario changed since its last decision. Record `rewords` or `changes`. |
   | `W-UNDECIDED` | A spec-tagged scenario has no live decision. |
   | `W-CONFLICT` | Two live decisions supersede the same record. |
   | `I-LEGACY` | Scenarios with no spec tag. They are legacy, not tracked. They get an id the first time a decision touches them. No backfill is needed. |
   | `I-EMPTY` | There are no decision records yet. |

   **Status.** For each scenario under a live decision, run `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh status <spec-id> --features <features_dir>` with the status flags below, and show a table of scenario and state: automated, planned, manual-only or blocked. Reconciliation never fails on status. A planned scenario under a live decision is healthy.

3. **Judgment check.** Read the live decisions (`decisions.sh show STORY` prints them in plain words). Report any two that contradict each other. A new decision that conflicts with a live one must supersede it. Report only. Do not edit.

4. **Audit mode** (`--all`). Re-derive the expected scenarios from the live decisions and compare them with the real `.feature` files. Report each difference as a finding. Never apply them.

5. **Story page** (`--show`). Run `"${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh show STORY --dir <decisions_dir> --features <features_dir>` with the status flags below, plus `--since` and `--channel` when given.

   | Config row | Flag |
   |------------|------|
   | `unautomated_tag` | `--planned-tag` |
   | `manual_only_tag` | `--manual-only-tag` |
   | `blocked_tag` | `--blocked-tag` |
   | `status_scope` | `--scope` |
   | `planned_dir` | `--planned-dir` |
   | `manual_only_dir` | `--manual-only-dir` |

   Pass a flag only when its row is set. Print the Markdown as is. It is generated and read-only, so say that discussion belongs in the story's channel.

### Rules

- The skill reports. It never edits scenarios or records, and it never commits.
- Do not run the tests. Reconciliation does not know if a scenario is red.
- The scenarios are the product spec. The log explains why they are that way.

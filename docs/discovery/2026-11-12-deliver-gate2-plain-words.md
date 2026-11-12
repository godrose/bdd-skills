# Discovery: `bdd:deliver` shows the product manager the second gate in plain words

Input: the first real flow run of `bdd:deliver` on fixture `d` (issue 41's example), the six earlier runs on fixture `c` (`docs/discovery/2026-11-11-deliver-flow-runs.md`), a read of `plugin/commands/deliver.md` step 2, `plugin/commands/design.md` Phase 4 and `flows/rules.pl`, and a discovery dialogue with the builder, one question at a time.

## Story

At the second gate the product manager approves the scenarios. `bdd:design` shows them with a mandatory per-step reuse audit table whose rows name step files and line numbers. `bdd:deliver` says only that design "shows the scenarios in plain words", and says nothing about the table. The flow harness counts the table as a break of its plain-words rule: in the six runs on `c` it broke in two or three messages every time, and in the real run on `d` in message 4 (`steps/records.steps.js` three times, `decision_log`, `docs/out-of-scope.md`). The two texts disagree, and the product manager is shown file names.

## Existing behavior (from the commands)

- `deliver.md` step 2 invokes `bdd:design`, which "audits step reuse and lints the draft, and then shows the scenarios in plain words and waits for the go-ahead".
- `design.md` Phase 4 requires the audit table before approval. Its rows carry a file and line. A flagged row (⚠) is resolved by choosing one of two fixes at the approval gate. It also shows an **Assumptions** list and an **Assumed, not checked** list.
- `deliver.md` puts technical remarks of the whole run in the "Developer note" of the final report.
- The harness rule hides a "For the developer" line only up to the next blank line, so a table under it is still counted.

## Agreed examples

- **E1** At the second gate the product manager sees the scenarios in plain words and as text, one plain sentence on reuse ("3 steps are reused and 3 are new"), and the **Assumptions** and **Assumed, not checked** lists. The full audit table is under a "For the developer" line: the label, a blank line, then the table.
- **E2** A finding that changes what a scenario proves (a title that claims more than the steps assert, data that does not fit a reused step, a setup that is assumed and not checked) becomes one plain question about the behavior, asked one at a time. The answer is recorded and the scenarios and the table are updated.
- **E3** A purely technical finding (a paraphrase of an existing step, a naming difference) is not asked. The designer takes the fix it prefers and lists it in the developer block.
- **E4** A technical remark that comes up before the report (the decision log script is missing, the lint did not run) goes on one "For the developer" line at the point it comes up. The developer note of the final report repeats it.
- **E5** With no developer watching, the same view applies. The table stays under the developer line, and the report's risks are as before.
- **E6** A project with nothing to reuse: the plain sentence says there are no steps to reuse yet, and every row of the table is new.
- **E7** Standalone `bdd:design` is unchanged. It still shows the table as it does now.
- **E8** In the flow harness a "For the developer" line, and a table that follows it after one blank line, are developer text. A table with file names anywhere else is still a break.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What does the product manager see of the audit? | A plain summary, and the full table under "For the developer". | The builder chose it. The table is still produced and reaches the pull request, and the product manager is not shown file names. |
| 2 | Who chooses on a flagged row? | Split by effect. A finding that changes what a scenario proves is asked in plain words. A purely technical one takes the designer's preferred fix and goes in the developer block. | The builder chose it. A weak title or a missing check must not be accepted without the product manager knowing, and paraphrase questions add noise. |
| 3 | How is the developer block counted by the harness? | The "For the developer" line and a table that follows it after one blank line are developer text. The command says: label, blank line, table. | The builder chose it. A table needs a blank line to render, and the rule stays strict about the rest of the message. It replaces the rule that a developer line ends at the first blank line. |
| 4 | Where do technical remarks go before the report? | On one "For the developer" line where they come up, repeated in the developer note. | The builder is not shown names mid-flow, and the developer finds the remark in the report. The real run said it in the body of the message. |
| 5 | Does `design.md` change? | No. | The table is also for people who use `bdd:design` alone and read paths. `deliver` decides how it presents what design produces. |
| 6 | Is the plain-words rule relaxed for tables? | No, beyond the developer block of decision 3. | The rule is the guard against this leak. |
| 7 | Do the remarks after the table need their own label? | Yes. Each technical remark is its own line that starts "For the developer:", one line each, never a list after the table. This makes decision 4 explicit in the command text. | A real run on fixture d put three bullets with code spans after the table and no label, so the rule counted them. The first wording said "anything else ... under a line", which the model read as one group after the table. |
| 8 | How does a run look at a filter that matches nothing? | The fixture project has a README that names `node src/show.js data/<records file> data/<filter file>`. | The same run tried `node -e`, which the harness does not allow, and left two examples unchecked. The command was only in the script header. A real project carries such a note. |
| 9 | Can the question about a finding and the request for the go-ahead share a message? | No. The question goes alone. The go-ahead is asked in a later message, after the scenarios are updated. | Run 3 sent "Question for you" and "Do I have your go-ahead" in one second-gate message, which broke one-question. The go-ahead also answers the question in a way the product manager cannot separate. |
| 10 | How does step 5 look at the result, and what if it cannot? | With the means the project has (a script, the command its README names), not with a command the assistant writes. A command that needs approval is not run. The example is reported as not looked at, the command goes on a "For the developer:" line, and the product manager is never asked to approve a command. | Run 3 asked the product manager in the body to approve a `node -e` line. It was not a tool denial: the allowed `show.js` with a filter file was never tried. A product manager cannot judge a command. |

## Existing users

- A project that uses `bdd:deliver` gets the new text when it updates the plugin or re-runs `install.sh`. Its `.claude/bdd-config.md` needs no change, because there is no new row.
- A project's own command with the same name is skipped by the installer, as it is now, and keeps its own text.
- Scenarios and steps in the project are not touched. Nothing in the project is renamed or deleted.

## First run

A fresh project with no steps has nothing to reuse. The second gate shows the scenarios, the sentence "there are no steps to reuse yet", and a developer block whose table has only new rows.

## Exclusions

- `design.md` and the audit table itself: unchanged.
- The Gherkin text of the scenarios: it is shown as text, as now.
- A config switch to show the table to the product manager. It can be added later, default off.
- Installing the decision log script into the flow fixtures, so the real run does not meet its absence: a separate change to the fixtures.
- An eval of the second gate: it needs a model run. The flow harness counts the rule when run by hand.

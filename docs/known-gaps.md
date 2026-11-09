# Known gaps

What this plugin does not check, or checks only in part. They are listed here so nobody has to find them in a chat or an eval note.

Each gap says what is not checked, why it is still open, and what would close it. A test checks that every entry has all three parts. It does not check that the entry is true, so when you close a gap, remove its entry in the same change.

### G1 The step-reuse audit eval misses some runs

**Not checked.** `design-vague-ac` has a grader, `has-step-reuse-audit`, that looks for the step-reuse audit in `design`'s answer. It fails in some runs where the model did the audit but worded it differently. It has been seen in local batches and in one CI run.

**Why.** The grader is a regex on the wording, not a judgment of the audit. The eval stays in the nightly with this noise because the other graders in the case are stable.

**Closed when.** The grader is split into a deterministic check plus a one-clause judge, as was done for the compound judge criteria, and passes in a week of nightly runs.

### G2 The lint eval does not prove `reports.feature` is unchanged

**Not checked.** `design-lint-draft` forbids the `Edit` tool, so `design` cannot edit the existing file that way. Nothing checks that `reports.feature` in the fixture is byte-identical after the run. A `Write` or a shell redirect could change it unnoticed.

**Why.** The case was written to catch the `Edit` path, which is the one the model took in the trial.

**Closed when.** The case compares the file with its fixture copy after the run, with a grader that reads the file.

### G3 No command enforces its rules with hooks

**Not checked.** Every rule in the commands is text the model follows, for example "write no `.feature` file before approval". Nothing blocks a tool call that breaks one. The evals sample behavior and fail when it drifts. They do not guarantee it.

**Why.** Hooks would tie the plugin to one host and add scripts for every rule. The commands are meant to work with any framework and with Bash as the way to run the user's own tools.

**Closed when.** A rule that must always hold has a hook or a deterministic check in CI, chosen one rule at a time.

### G4 `design-lint-draft` runs only by hand

**Not checked.** The nightly runs five of the six eval cases. `design-lint-draft` needs plain `Bash`, and the agent's shell can see the variables that carry the login token.

**Why.** Running it in CI would hand the token to a shell the agent controls. The narrow `Bash(...)` grants that the other cases use deny its chained commands.

**Closed when.** The token can be kept away from the agent's shell, or the case works with narrow grants.

### G5 The red-first check has text tests and no eval

**Not checked.** `tests/test_red_first.sh` checks that `commands/implement.md` states the red-first check. Nothing runs `implement` on a fixture project and looks for the `Red-first:` line, or that the file with the forced break was restored.

**Why.** An `implement` eval needs a fixture with a test runner that works on the CI machine, which is a larger piece of work than the check itself.

**Closed when.** An `implement` eval covers a natural red, a forced red and a scenario that is not seen red, and runs in the nightly.


### G6 No eval runs the decision log with its script present

**Not checked.** The marketplace plugin does not ship `decisions.sh`, so every eval runs with the script missing. `triage-approval-gate` has `decision_log: on` and so runs the "needs the project install, nothing was recorded" path. Nothing runs `design`, `triage` or `reconcile` against the script that `install.sh` copies.

**Why.** The eval tool loads only the plugin folder, and the plugin cannot carry the script. A case that needs it must put the script into the fixture, and the fixture is not scanned.

**Closed when.** A case's scaffold copies `scripts/decisions.sh` into the fixture as `.claude/scripts/decisions.sh`, and runs a project-install copy of the commands against it.

### G7 No eval runs a whole `deliver` flow

**Not checked.** `deliver-first-gate` stops at the first question. Nothing runs `/bdd:deliver` through the second gate, the implement and run steps, the two kinds of stop, or the final report. The report shape, the out-of-scope list and the feature-description lines are checked only as text in `tests/test_deliver.sh`.

**Why.** A whole flow needs several answers from a user and a fixture with a test runner that works on the CI machine. The eval tool runs one prompt per case.

**Closed when.** A case drives `deliver` through a scripted conversation on a fixture with a working test runner, and checks the report and the files it writes.

### G8 Out-of-scope items are not linked to a tracker

**Not checked.** `deliver` writes each exclusion as one line in the out-of-scope file. In a team that uses Jira, Monday or a similar tracker, each excluded item would usually become a ticket of its own, so it is planned and not forgotten. Nothing creates the ticket, links the line to it, or tells you when the ticket is done and the line is stale. The first trial on a real project wrote its exclusions to a file only.

**Why.** Reaching a tracker needs the optional **requirements-sync** skill, and its role has no "create an item" action. The file works for one repository and needs no setup.

**Closed when.** An exclusion can name a tracker key in its line, `deliver` offers to create the ticket through the configured skill, and a later run on the same story reads the key and says whether the ticket is closed. This is a design decision first, so it starts with discovery.

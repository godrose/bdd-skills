# Discovery: the decision log checks as scenarios

Input: `tests/test_decisions.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

`scripts/decisions.sh` keeps a project's decisions in append-only JSON Lines files. It checks, finds and shows them. Migrate the checks of `tests/test_decisions.sh` to scenarios, in six feature files. A migration adds no checks.

## Agreed examples (all from code)

Validating a log
- **E1** A valid log passes and reports no errors.
- **E2** A line that is not JSON fails. The message names the file and line 2.
- **E3** A record with a missing field fails. The message names the field.
- **E4** A record from a newer format version fails and says to update the skills.
- **E5** An unknown effect kind fails.
- **E6** An unknown source role fails.
- **E7** A record id must start with its story's name, taken from the file name.
- **E8** A badly formed scenario id fails. The message names it.
- **E9** A duplicate record id fails.
- **E10** Three dangling references (superseded, resolved, confirmed) are each reported.
- **E11** CRLF endings, blank lines and a missing final newline are tolerated.
- **E12** A missing decisions folder passes and says the log is empty.
- **E13** An empty log file passes.
- **E14** Without `jq` the script exits 2 and names `jq`.
- **E15** The folder can come from the environment. A flag wins over it.
- **E16** With neither flag nor environment, the default folder is used.

The append-only check against a base ref, and merging parallel appends
- **E17** Appending a record passes.
- **E18** Editing a record fails. The message names the file and line 1.
- **E19** Emptying a log file fails.
- **E20** Deleting the first line of a log fails.
- **E21** Deleting a log file fails.
- **E22** A new log file passes.
- **E23** First adoption passes: the base has no decisions folder.
- **E24** A log with CRLF at the base and LF now passes.
- **E25** Outside a git repository the script exits 2.
- **E26** An unknown base ref exits 2.
- **E27** Two branches that each append a record merge with no conflict and keep all three records, under the union-merge rule.

Looking up a scenario and its fingerprint
- **E28** A plain scenario has an 8-character fingerprint.
- **E29** Other tags, comments, spacing, blank lines and CRLF do not change it.
- **E30** Flipping a status tag does not change it.
- **E31** Rewording a step changes it.
- **E32** Changing a cell in an outline's examples changes it.
- **E33** An id in a comment is not a tag: "not found", exit 1.
- **E34** An id inside a step is not a tag: exit 1.
- **E35** An id on the Feature line is not a scenario tag: exit 1.
- **E36** A duplicate id in one file is "ambiguous", exit 1.
- **E37** A duplicate id across files exits 1.
- **E38** Two ids on one scenario share a fingerprint.
- **E39** A file with no final newline works.
- **E40** A change in a neighbouring scenario does not move this fingerprint.
- **E41** Without a features folder the script exits 2.
- **E42** Changing a tagged examples block changes the fingerprint. The scenario after it keeps its tag.
- **E43** A tag inside a docstring is not a scenario tag. The docstring text is part of the fingerprint. The check never mentions the fake id and counts no legacy scenarios.

Live decisions and findings when reconciling
- **E44** A healthy log passes with no warnings.
- **E45** A decision about a scenario that does not exist fails as an orphan.
- **E46** A removed scenario is not an orphan and not undecided.
- **E47** A scenario that still exists after its removal decision gets an undecided warning.
- **E48** A changed scenario is a drift warning, not a failure. A later rewording decision clears it.
- **E49** A superseded decision is not live. It causes no orphan.
- **E50** Two decisions that supersede the same one give a conflict warning.
- **E51** A scenario with no decision gets an undecided warning.
- **E52** Scenarios without ids are counted as legacy.
- **E53** A duplicate scenario tag fails.
- **E54** Exclude, defer and plain rationale decisions pass.
- **E55** An open item with a resolving decision passes.
- **E56** With a base ref, only changed stories are checked for drift. Without a base, all are.
- **E57** With a base ref, a deleted feature is an orphan. A changed scenario is drift.

Status
- **E58** A pending tag means planned.
- **E59** No marker means automated.
- **E60** A manual-only tag means manual-only.
- **E61** Manual-only wins over pending.
- **E62** A blocked tag means blocked only when the blocked tag is given.
- **E63** A custom planned tag works.
- **E64** With feature scope the Feature's tags count. With scenario scope they are ignored.
- **E65** With directory scope, a scenario in the planned folder is planned.
- **E66** With directory scope, a scenario in a nested manual-only folder is manual-only.
- **E67** A scenario that does not exist exits 1 with "not found".

Show
- **E68** Show exits 0, with a headline and four sections in order.
- **E69** Each agreed line carries its status. A URL source is a link.
- **E70** No record ids and no fingerprints appear.
- **E71** A resolved open question is not listed as open. An unresolved one is.
- **E72** A superseded decision and a closed open question appear only in history.
- **E73** The output is the same on a second run. Outside git it says so.
- **E74** A channel link is shown as "Discussion".
- **E75** An unknown story exits 0 and says no decisions are recorded.
- **E76** Special characters are kept. Empty sections are absent. With nothing agreed it says so.
- **E77** In a git repository it names the commit and does not mention uncommitted changes when there are none.
- **E78** With a since ref, a "changed since you last looked" section lists Changed, Removed, Left out, Postponed and Added, and notes uncommitted changes. Without the ref it is absent.
- **E79** A source that is not a URL is shown as plain text, not a link.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Is E27 migrated although it tests git's union merge? | Yes. | The builder named merging parallel appends as a group. |
| 2 | Where do the scope checks with a base ref go? | With reconciling (E56, E57). | They decide which findings appear. |
| 3 | Where do the late fingerprint fixes go? | With the fingerprint file (E42, E43). | They are about fingerprints and tags. |
| 4 | Where does the plain-text source go? | With show (E79). | It is about how show prints a source. |

## Existing users

Nothing changes in a user's project or in the plugin folder. The script is not touched. The version does not change.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new feature files run beside the bash file until it is deleted.

## Exclusions

- Any new check. Reason: a migration adds none.
- The bash file's own helpers and exit-code counting. Reason: they test the harness, not the script.
- Exact wording beyond the fragments the old file matched. Reason: the scenarios keep to those fragments.

## Kept as they are

- Most output checks are substring matches. A reworded message that keeps the fragment still passes.

# Discovery: `bdd:discover` looks at what exists before the first question

Input: the two trials of `/bdd:deliver` on a real project (`docs/trials/2026-11-09-deliver-pm-session.md`), a read of `plugin/commands/discover.md`, and a discovery dialogue with the builder, one question at a time. It covers handoff suggestions 1 and 2.

## Story

A product manager describes a change. The assistant asks questions before it has looked at what the project already has. Twice in trial 1 it stated something that was false, and once in trial 2 a product decision came up late, after the examples were approved. Discovery should look first, say what it found in plain words, and ask about a shown value only when the answer is a product decision.

## Existing behavior (from the command)

- Step 1 restates the story and Step 2 proposes examples. Step 3 mines vocabulary and Step 3b looks for existing behavior in the code. Both come after the questions start.
- Step 3b reads domain code, handlers and unit tests. It does not read existing scenarios for the behavior itself, and it does not read screens.
- Step 3b already says: when the behavior exists, mark values "from code", and when the repo has no source, ask where the behavior is defined.
- The trials showed the cost. Discovery said delete had no scenarios, but one screen check existed. It said no screen showed dates, but the list had a "Created on" column. It asked about timing precision only at design, after the checklist was approved.

## Agreed examples

- **E1** Before the first question, discovery looks for the story's key terms in scenarios, step code, screens and code. This is a new Step 0, "Look first". It only reads.
- **E2** Each finding is one plain sentence at the start of the restatement. The paths go on one trailing line labelled "For the developer".
- **E3** When nothing is found, it says one line: "Looked at scenarios, steps, screens and code for these terms: found nothing."
- **E4** When something cannot be looked at, it says "not looked at: <why>". Examples are a project with no screens, a repo with no source, or a shallow clone.
- **E5** When the behavior already exists, the story becomes scenarios for existing behavior, with values marked "from code". This is the Step 3b rule, and it now applies from Step 0.
- **E6** For a value the system sets or changes without the user (a status, a time, a count, a total), discovery finds the source in the code, states it "from code", and asks one plain question about the consequence, such as a delay or the precision.
- **E7** When the source cannot be found, it is an open question for the developer ("Where is this set?"). The pack is not ready until it is answered.
- **E8** A value the user typed and the system only stores and shows back is not asked about.
- **E9** The pack gets two short sections: "What exists" and "Shown values and their source".

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | When does discovery look at what exists? | Before the first question, in a new Step 0 "Look first". Steps 3 and 3b stay for vocabulary and defects. | Both retractions in trial 1 came from stating something before looking. A named step is visible and a test can pin its place before Step 1. |
| 2 | How are findings reported? | One plain line per finding at the start of the restatement, with the paths on one trailing line "For the developer". "Found nothing" and "not looked at: <why>" are said aloud. | The product manager may not know where code is, so the sentence must stand alone. A silent miss is what went wrong in trial 1. |
| 3 | How is a shown value handled? | Find the source in the code. State it "from code". Ask the product manager only about the consequence (delay, precision). | A product manager cannot say where a status comes from. They can say whether a delay is acceptable, and that was the question trial 2 asked too late. |
| 4 | The source cannot be found? | An open question for the developer. The pack is not ready until it is answered. | Same rule as Step 3b for a repo with no source. Designing without the source caused the late stop in trial 2. |
| 5 | Which values? | Those the system sets or changes without the user doing it in the same moment: a status, a time, a count, a total, anything computed or set by another service. | These are the values that can differ from what a scenario declares. A value the user typed is noise. |

## Existing users

- A project that uses `bdd:discover` or `bdd:deliver` gets Step 0 when it updates the plugin or re-runs `install.sh`. It needs no config change, because there is no new row.
- Nothing is installed or deleted, and a user's own command or skill with a similar name is not touched.
- Existing scenarios and the out-of-scope list are read and never changed.

## First run

A fresh project with no scenarios, steps, screens or code sees "found nothing" and carries on. Empty folders still report "nothing to mine" in Step 3.

## Exclusions

- Starting the app and looking at it: that stays in step 5 of `deliver`.
- A design-time check that declared states survive in the system: a separate discovery, still open.
- A config switch: it can be added later, default on, as a dated reversal.
- An eval of Step 0: text tests pin the rule.
- Scanning outside the repository, such as a tracker or a wiki.
- The size gate is unchanged. A trivial change skips discovery, so it skips Step 0.

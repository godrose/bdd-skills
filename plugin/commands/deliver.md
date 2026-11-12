---
description: "Carry a change from a plain description to verified scenarios in one conversation: discover, design, implement and run, with two light approvals and a report in plain language"
---

## BDD Deliver

Carry one change from a description to scenarios that pass, in one conversation. This is a **methodology skill** that composes the existing ones: `bdd:discover`, `bdd:design`, `bdd:implement` and `bdd:run`. It does not replace them and does not repeat their work. It sequences them, turns their stops into questions, then looks at the result and writes the report.

It is for a product manager, with or without a developer or architect watching. The product manager describes a change and answers questions about how it should behave. A developer, when there is one, answers what is technical. When there is none, each technical stop becomes a risk in the report, in plain words. After the first delivery the team shares one language, and each later change starts as a description and adds visible value on top of what exists.

**Before starting**, read `.claude/bdd-config.md` for project conventions and skill role mappings. If `.claude/bdd-config.md` does not exist, say so and stop. Tell the user to create it from `bdd-config.template.md`; re-running `install.sh` also creates it.

> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`. The template is at `${CLAUDE_PLUGIN_ROOT}/bdd-config.template.md`.

This command pre-approves nothing. Claude Code asks before each shell command and each file write, so the person running it must be there to approve each one.

### Input

One of:
- A description of the change, typed in the session
- A tracker key or URL (needs the optional **requirements-sync** skill). If none is configured, ask for the text.

### Size gate

Apply the size gate from `bdd:discover`. A one-line fix, a rename or a copy edit needs no discovery: say so in one sentence, skip step 1, and go on to step 2 with the change as described.

### Workflow

#### Step 1: Discover

Invoke the **discoverer** skill (`bdd:discover`) with the description. Ask one question at a time and wait for each answer. Read the out-of-scope list (see Recording below) before you propose anything, and do not propose what it excludes. If the answer would reverse an entry, ask that as one question.

If the behavior already exists, discovery turns the description into scenarios for existing behavior, with the exact values marked "from code". If every agreed example is already covered and passing, say that the change already works and stop after the report.

The result is the **checklist of agreed examples**: a numbered list in plain words (`E1`, `E2` and so on), each marked confirmed. Show it to the product manager.

**Do not go on until the product manager has approved the checklist.** This is the first approval. If the session ends before the examples are approved, nothing is written.

#### Step 2: Design

Invoke the **designer** skill (`bdd:design`) with the checklist. The approved checklist counts as the approval of the examples, so do not ask for it again. Design writes the scenarios, audits step reuse and lints the draft. What the product manager sees at this gate:

- The scenarios in plain words and as text.
- One plain sentence on reuse, for example "3 steps are reused and 3 are new", or "there are no steps to reuse yet".
- The **Assumptions** list and the **Assumed, not checked** list, as design writes them. They are in plain words already.
- Every finding that changes what a scenario proves (a title that claims more than the steps assert, data that does not fit a reused step, a setup that is assumed and not checked) as one plain question about the behavior, asked one at a time. Record the answer and update the scenarios.
- A finding that is only technical (a paraphrase of an existing step, a naming difference) is not asked. Take the fix the designer prefers and list it in the developer block.

Put the per-step audit table, and anything else with file names or code (the lint did not run, the decision log script is missing), under a line that starts "For the developer", then a blank line, then the table. The product manager does not need to read it.

Wait for the go-ahead. The go-ahead is the second approval, and it can come from either person.

No `.feature` file is written before the go-ahead.

If **workflow_mode** is `specify-only`, stop after the go-ahead. Say that the scenarios are specified and not implemented, and give the report for what exists.

#### Step 3: Implement

Invoke the **implementer** skill (`bdd:implement`) for each approved scenario. It runs its own fix loop and its red-first check. If `bdd:design` already invoked the implementer for a scenario after the go-ahead, do not invoke it again for that scenario. This step covers only the scenarios that are not yet implemented.

#### Step 4: Run

Invoke the **test-runner** skill (`bdd:run`) for the new scenarios and for the affected feature. The affected feature is the `.feature` files this change wrote or edited, plus any other feature file that uses a step whose code the increment changed.

#### Step 5: Look at the result

Passing scenarios do not show that they describe what a person sees. A passing run shows that the scenarios and the system agree with each other. It does not show that either matches the agreed examples. This step looks at the system itself and does not run the suite again. Run a scenario again only to take a screenshot during it.

Before the report, look at the real result of every new or changed example, by the means its layer offers. Use the same data the scenarios use.

- **A screen.** Open the app on that data and look at each page the change touches. In a browser-driven project, take a screenshot during a run of the scenario, or use the project's own way to start the app, and read it. Compare it with the agreed examples: every value, status and row the change touches, and anything the page shows that no scenario names, such as an empty field or a leftover label.
- **No screen.** For an API or a service, make a real request to the running system and read the response. For stored data, read the stored record. For a background job, read the log or the record it writes. Compare it with the agreed examples in the same way.
- **Declared against seen.** For every state that a scenario's data declares, such as a status or a flag, check that the system still shows it once it is running. A fixture can declare a state that the system changes at once. The scenario then passes while it describes something that never happens.

What you see decides the next step. A difference from an agreed example, or a surprise nobody described, is a stop. If the behavior is in question, ask the product manager one question about it. Otherwise fix the step code, the data or the product, and run again within the fix loop's cap. Never change an agreed example or its expected values to match what you saw.

If the result cannot be looked at, for example the app cannot be started here, do not skip this silently. Say what was not looked at and why. Never report an example as passed when its result could be looked at and was not.

### When a step stops

Sort every stop by kind.

- **A product decision is asked at once.** Examples: the data does not fit an agreed example, an earlier scenario now fails and nobody said the change was intended, or the code shows a behavior nobody described. Explain what was found in plain words and ask one question about that behavior, record the answer, and resume. Do not ask the product manager to approve again what they already approved.
- **A technical stop is parked.** Example: a step failed three times. Report the example as failed or as couldn't be checked, with the evidence for the developer. The independent examples go on. Collect the parked stops into the "Not checked, and what it risks" section of the report. Give each one plain sentence on what could go wrong for the users, then the evidence on a "For the developer" line. Never name a file, a field, a function or a status in the plain sentence. Do not ask whether there is a developer, and do not word the report differently for a person who has none. A parked example is never reported as passed.

When a check fails against an agreed example, fix the step code or the implementation and re-run, within the fix loop's cap, and never change an approved scenario or its expected values to make a check pass. If the scenario is what is wrong, that is a product decision: ask.

### Recording

Record each answer where it will last.

- **Answers that shaped a scenario** go in the text under `Feature:` in the `.feature` file, one line each: `Decision (YYYY-MM-DD): <answer>. Why: <reason>.` Write them in the same change as the scenarios.
- **Exclusions and removals** go in the out-of-scope list, the file named by **out_of_scope_file**. One line each: `YYYY-MM-DD | excluded: <what> | why: <reason> | revisit when: <optional>`, or `removed:` in place of `excluded:` for something taken out. Write each exclusion when the product manager approves the checklist, because exclusions come up in step 1. Write a removal when the change that makes it is approved. Create the file when the first entry is written, and only after the product manager has approved something. Never rewrite a line that is already there. If the file is not in this format, read it as plain text and add lines in this format.
- **A reversal** of an entry is a new dated line that says so, and leave the old entry in place.
- **Deleted features.** Features may have been deleted outside this flow. Look for the story's terms in them with `git log --diff-filter=D --name-only -- '*.feature'` and `git log -S`. This uses local git only. If the clone is shallow and has no history, say that you cannot look.

- **The decision log.** When **decision_log** is `on`, `bdd:design` and `bdd:triage` record approved decisions. If their script is missing, they say so. Add "Nothing was recorded" to the developer note. The answers are still in the feature file.

There is no resume file. Before approval the state is in the conversation. After the `.feature` file is written, the files are the state, and running this command again on the same story reads what exists.

### The report

End with a report that can go into a pull request description. Plain words, in this shape, with one regression line:

```
Delivered: <the change in one sentence>

E1 <example in plain words>: passed
E2 <example in plain words>: failed - <what happened>
E3 <example in plain words>: couldn't be checked - <why>

Regression: <N> earlier scenarios in <the affected feature> still pass.
<or, for each earlier scenario that now fails: what used to be true, and the decision that was made>

Seen: <what was looked at, and how: a page, a request, a record>
<or: not looked at: <why>>

Not checked, and what it risks:
- E2 <what could go wrong for the users, in plain words>. For the developer: <what to look at>

Developer note: <anything that was not recorded, anything surprising seen in step 5, and the technical remarks and fixes from the second gate>
```

- "Couldn't be checked" covers an example whose result was not looked at in step 5 (the Seen line says why), a scenario still tagged `@pending`, a scenario that stays manual-only, a scenario the red-first check marked "not seen red", and any run that executed zero tests. A run of zero tests is never a pass.
- Name each example by the words the product manager agreed.
- Put anything surprising that you saw in step 5 in the developer note, even when it was fixed.
- Leave the developer note out when there is nothing in it.

- Leave the "Not checked, and what it risks" section out entirely when nothing was parked: no heading, and no line that says nothing was parked.
### Rules

- Ask one question at a time. Use the project's words.
- Never invent acceptance criteria. Ask.
- Never skip an approval, and never ask for one twice.
- Do not write step code yourself. The implementer does.

### Defaults when config rows are absent

- No **out_of_scope_file**: use `docs/out-of-scope.md`.
- No **requirements-sync** role: work from the text you were given.
- No **workflow_mode**: `specify-and-implement`.

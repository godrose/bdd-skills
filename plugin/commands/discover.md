---
description: "Discover what to build before designing scenarios: turn a story into questions, examples, edge cases and exclusions through a dialogue"
---

## BDD Discover

Turn a story into a shared understanding before any scenario is written. This is a **methodology skill**. It runs the conversation that removes surprises, then hands a discovery pack to the **designer** skill (`bdd:design`).

The person who owns the story is the **builder**. The builder may be a lone developer, or a developer working from a product manager's story. You take the questioning side: you ask what a skeptical product manager and a careful tester would ask.

**Before starting**, read `.claude/bdd-config.md` for project conventions and skill role mappings.

### Input

One of:
- A tracker key or URL (needs the optional **requirements-sync** skill)
- Story text pasted into the session
- A description of what the builder wants, typed in the session

### Size gate

Apply the size gate once you have read the story. Some changes do not need discovery: a one-line fix, a rename, a copy edit. If the change is that small, say so in one sentence, skip discovery, and point the builder at `bdd:design` or at the change itself. Do not interrogate a builder about a trivial change.

### Workflow

Discovery is a dialogue. Ask **one question at a time**. Wait for the answer. Use the answer to choose the next question. Do not hand the builder a list of twenty questions.

#### Step 0: Look first

Look at what the project already has before the first question. This only reads. Change nothing.

1. Take the story's key terms: the action, the thing it acts on, and any value the story shows. Search for them in the scenarios (**features_dir**), every folder of the **steps_dir**, the screens (views, templates and page objects, when the project has a client), and the domain and server code. Read the out-of-scope list too (the file named by **out_of_scope_file**).
2. Say what you found at the start of the restatement in Step 1. Write one plain sentence per finding, in words a product manager can check without knowing where the code is. Put the paths on one trailing line: "For the developer: <paths>".
3. If you found nothing, say "Looked at scenarios, steps, screens and code for these terms: found nothing."
4. If something cannot be looked at, say "not looked at: <why>". Examples: the project has no screens, the repo holds only features, or the clone is shallow. Never skip it silently.
5. For each value the story shows that the system sets or changes without the user doing it in the same moment (a status, a time, a count, a total, anything computed or set by another service), find what sets it in the code. State it "from code". Then ask the product manager one plain question only about what it means for them, such as a delay or the precision. Do not ask where the value comes from. A value the user typed and the system only stores and shows back needs no question. If you cannot find what sets it, ask the developer "Where is this set?" as an open question. The pack is not ready until it is answered.
6. If the behavior already exists, Step 3b applies from here: the story becomes scenarios for existing behavior, with values marked "from code".

#### Step 1: Understand the story

1. If a tracker key is given and a **requirements-sync** skill is configured, invoke it to fetch the story, acceptance criteria, comments and linked items. Otherwise use the text you were given. If you were given only a tracker key and no **requirements-sync** skill is configured, ask the builder to paste the story.
2. Restate the story in plain words, beginning with what Step 0 found, and ask the builder to correct it.
3. If the acceptance criteria are missing or vague, stop and ask. Do not draft scenarios from a guess.

#### Step 2: Find examples

1. Propose concrete examples in the builder's own words. Use real values and real situations. Do not write Gherkin yet.
2. After each example ask whether it is right, wrong, or missing something.
3. Propose edge cases and negative paths as questions: "What should happen when ...?" Cover empty input, repeated actions, missing permissions, and the case where the thing already exists.

#### Step 3: Check the vocabulary

1. Mine the **features_dir** and every folder of the **steps_dir** (one path, or several comma-separated) for the terms the project already uses: names of things, casing, wording of similar steps. If the directories are empty, report "nothing to mine" and continue.
2. If a **glossary_file** is configured, read it too.
3. If a **lint** command is configured, run it on any draft text that exists and report what it flags.
4. List every term from the story that matches nothing the project already says. Mark each one "unknown, ask the builder". Prefer an existing term over a new one.

#### Step 3b: Look for existing behavior

Before you treat the story as new work, look for the behavior in the code. Search the domain and server code, API handlers and unit tests for the story's key terms (for example the action and the thing it acts on).

1. If the behavior already exists, say so and name the files. Then change the story to acceptance scenarios for existing behavior. Use the code as the source for exact values and messages, and mark each one "from code". Re-check your examples and exclusions against it. An exclusion the code contradicts becomes "needs decision" for the builder.
2. Note values in the code that look wrong (for example a message that shows an id where the others show a name). List them as possible defects to raise separately. Do not change the behavior to fit the scenario.
3. If the repo holds no source, only features, say so and continue. Ask the builder where the behavior is defined.
4. Look for what was ruled out. Read the out-of-scope list, the file named by **out_of_scope_file**, and propose nothing it excludes. Features may have been deleted: search them for the story's key terms with `git log --diff-filter=D --name-only -- '*.feature'` and `git log -S`. This uses local git only. In a shallow clone with no history, say that you cannot look.

#### Step 4: Decide what is out

List the candidate exclusions: cases you considered and propose to leave out. Give a reason for each. The builder confirms or overrules each one. An exclusion nobody confirmed is a gap.

#### Step 5: Hand off

Present the discovery pack (below). It stays in the conversation by default. Save it to **discovery_dir** only when the builder asks. A team may paste the saved pack into a pull request or a tracker comment.

### Discovery pack

```
## Story
<restated story, corrected by the builder>

## What exists
<what Step 0 found, one plain sentence each, then "For the developer: <paths>"; or "found nothing"; or "not looked at: <why>">

## Shown values and their source
<each value the system sets or changes without the user: what sets it, marked "from code", and the answer about what it means for the user; or "where is this set?" as an open question; or "none">

## Open questions
<questions still unanswered, most important first, or "none">

## Candidate examples
<concrete examples in plain words, each marked confirmed or proposed>

## Agreed examples
<only when the builder has confirmed examples: a numbered checklist in plain words, E1, E2 and so on, each marked confirmed. `bdd:deliver` shows this list to the product manager for approval>

## Edge and negative cases
<cases with the agreed outcome, or the question still open>

## Vocabulary check
<terms reused from the project, terms flagged unknown, lint findings>

## Candidate exclusions
<case, reason, confirmed or not>

## Readiness
<ready for bdd:design, or what is still missing>
```

The pack is **ready** only when no open question is unanswered and every exclusion is confirmed. A shown value whose source is unknown is an open question.

### Rules

- Reuse the project's existing words. A new term needs a stated reason.
- Never invent acceptance criteria. Ask.
- Never write step definitions or touch the test code. That is the implementer's job.
- If the builder says "just guess", propose one concrete answer and mark it as your guess.

### Defaults when config rows are absent

Older `bdd-config.md` files do not have the newer rows. A value still in `<...>` placeholder form counts as empty. Use these defaults and do not fail:

- No **requirements-sync** role: work from the text you were given.
- No **glossary_file**: skip the glossary read.
- No **lint** command: skip the lint step.
- No **discovery_dir**: use `docs/discovery` when the builder asks to save.
- No **out_of_scope_file**: use `docs/out-of-scope.md`. If the file is missing, there is nothing ruled out yet.
- No **features_dir** or **steps_dir** entries that exist on disk: report "nothing to mine".

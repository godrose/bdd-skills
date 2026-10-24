---
description: "Discover what to build before designing scenarios: turn a story into questions, examples, edge cases and exclusions through a dialogue"
allowed-tools: ["Agent", "Bash", "Read", "Grep", "Glob", "AskUserQuestion"]
---

## BDD Discover

Turn a story into a shared understanding before any scenario is written. This is a **methodology skill**. It runs the conversation that removes surprises, then hands a discovery pack to the **designer** skill (`bdd-design`).

The person who owns the story is the **builder**. The builder may be a lone developer, or a developer working from a product manager's story. You take the questioning side: you ask what a skeptical product manager and a careful tester would ask.

**Before starting**, read `.claude/bdd-config.md` for project conventions and skill role mappings.

### Input

One of:
- A tracker key or URL (needs the optional **requirements-sync** skill)
- Story text pasted into the session
- A description of what the builder wants, typed in the session

### Size gate

Apply the size gate once you have read the story. Some changes do not need discovery: a one-line fix, a rename, a copy edit. If the change is that small, say so in one sentence, skip discovery, and point the builder at `bdd-design` or at the change itself. Do not interrogate a builder about a trivial change.

### Workflow

Discovery is a dialogue. Ask **one question at a time**. Wait for the answer. Use the answer to choose the next question. Do not hand the builder a list of twenty questions.

#### Step 1: Understand the story

1. If a tracker key is given and a **requirements-sync** skill is configured, invoke it to fetch the story, acceptance criteria, comments and linked items. Otherwise use the text you were given. If you were given only a tracker key and no **requirements-sync** skill is configured, ask the builder to paste the story.
2. Restate the story in plain words and ask the builder to correct it.
3. If the acceptance criteria are missing or vague, stop and ask. Do not draft scenarios from a guess.

#### Step 2: Find examples

1. Propose concrete examples in the builder's own words. Use real values and real situations. Do not write Gherkin yet.
2. After each example ask whether it is right, wrong, or missing something.
3. Propose edge cases and negative paths as questions: "What should happen when ...?" Cover empty input, repeated actions, missing permissions, and the case where the thing already exists.

#### Step 3: Check the vocabulary

1. Mine the **features_dir** and **steps_dir** for the terms the project already uses: names of things, casing, wording of similar steps. If the directories are empty, report "nothing to mine" and continue.
2. If a **glossary_file** is configured, read it too.
3. If a **lint** command is configured, run it on any draft text that exists and report what it flags.
4. List every term from the story that matches nothing the project already says. Mark each one "unknown, ask the builder". Prefer an existing term over a new one.

#### Step 4: Decide what is out

List the candidate exclusions: cases you considered and propose to leave out. Give a reason for each. The builder confirms or overrules each one. An exclusion nobody confirmed is a gap.

#### Step 5: Hand off

Present the discovery pack (below). It stays in the conversation by default. Save it to **discovery_dir** only when the builder asks. A team may paste the saved pack into a pull request or a tracker comment.

### Discovery pack

```
## Story
<restated story, corrected by the builder>

## Open questions
<questions still unanswered, most important first, or "none">

## Candidate examples
<concrete examples in plain words, each marked confirmed or proposed>

## Edge and negative cases
<cases with the agreed outcome, or the question still open>

## Vocabulary check
<terms reused from the project, terms flagged unknown, lint findings>

## Candidate exclusions
<case, reason, confirmed or not>

## Readiness
<ready for bdd-design, or what is still missing>
```

The pack is **ready** only when no open question is unanswered and every exclusion is confirmed.

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
- No **features_dir** or **steps_dir** entries that exist on disk: report "nothing to mine".

# Discovery: labelled examples are the source, and the Gherkin is hidden

## Story

People who approve and write behavior find Gherkin too formal. They must read it to approve it and write it to change it. The plugin already shows scenarios "in plain words" at approval, but the formal text is still the source of truth, so the author still writes it and the reviewer still meets it. The change is to make labelled examples in domain words the source and to generate the Gherkin from them, as a hidden layer that only a developer sees. The pillars stay: concrete examples, a conversation before code, a spec that runs and fails when behavior drifts, a repeatable verdict, and a trace from example to result.

The people who do not want Gherkin at all were asked about. The builder chose to hide it from authors and approvers (H1), not to remove it from the repo (H2, ordinary tests in the project's own framework). H2 is a possible later step.

## Why this is on its own branch

This change asks whether Gherkin should be visible at all, and that touches the value the plugin claims: a spec people read, approve and keep. If the examples carry that value better, the plugin changes what it asks of its users. If they do not, the Gherkin stays the source and this work is dropped.

So the work builds up on `feat/examples-source`, one PR per slice, and `main` keeps shipping 0.7.x fixes in the meantime. No slice bumps the version or adds a CHANGELOG entry. The branch reaches `main` once, as a release PR, and only after the trial on a real project (slice 4) settles the open points. The trial may decide not to ship it. That is an acceptable result, and the pack records why.

## Existing behavior

- `discover` writes a pack with a numbered list of agreed examples (E1, E2 and so on) in plain words. It is a record of one conversation and nothing keeps it current.
- `design` drafts Gherkin from the pack, audits the reuse of steps, tags each scenario with `@<scenario_id_prefix><slug>`, shows the scenarios in plain words and waits for the go-ahead.
- `deliver` has two approvals: the agreed examples, then the scenarios in plain words. Technical text goes under "For the developer:", and the flow harness counts a leak outside it as a break.
- The decision log fingerprints a scenario's text and records an approved scenario.
- The Gherkin is the source of truth, and it is written and edited by hand or by `design`.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| E1 | `spec_source` is `examples` (the default) and a new feature is discovered | `discover` writes `<features_dir>/<feature>.examples.md` with a rule and labelled examples, `E1.`, `E2.` and so on. Each holds the situation, the action and the outcome in domain words with concrete values. The pack is still written, as history. |
| E2 | The examples are ready | One approval, of the examples file. `design` then generates the scenarios without a second gate. |
| E3 | A scenario is generated from example E2 | It carries its spec id, the example id, a hash of the example text and a hash of its own generated text. A comment at the top says it is generated and to change the example. The wording reuses the existing steps first. |
| E4 | An example has no scenario, or a generated scenario has no example | The guard fails and names the id. |
| E5 | A concrete value in an example (a number, a name, a quoted text) does not appear in its scenario | The guard fails and names the value. |
| E6 | The text of an example changes after its scenario was generated | The guard fails on the stored hash. Design regenerates only that scenario. `implement` changes a step only when its wording changed. |
| E7 | A generated scenario is edited by hand | The guard fails on the hash of its generated text. The change goes into the example. |
| E8 | A scenario has no example id | It is Gherkin-owned, as today. No guard touches it. A technical scenario can stay this way. |
| E9 | Generation finds something that changes what a scenario proves: a title that claims more than the steps check, data that does not fit a reused step, a setup that is assumed and not checked | One plain question about the behavior, asked alone. The answer goes into the example and the scenario is regenerated. A purely technical finding is not asked and goes under "For the developer:". |
| E10 | The report of a run | It names each example by id in plain words: "E2 passed", "E3 failed: the label showed nothing instead of 'late by 3 days'". It traces back by id. |
| E11 | Gherkin keywords, step text, step file names or the reuse table | They appear only under "For the developer:". A developer can ask to see the generated scenario for an example and gets it. The flow harness flags them anywhere else. |
| E12 | `spec_source` is `gherkin` | The plugin works as it does today. |
| E13 | A project has `.feature` files and no examples file | Nothing changes. They are Gherkin-owned, with `spec_source` at its default or not. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | The source is labelled examples: an id, the situation, the action and the outcome, with concrete values. Chosen by the builder. | A light shape that a script can check without a model, and the author writes in words. |
| 2 | The examples live in a file per feature, beside the generated `.feature` file. The pack stays as history. Chosen by the builder. | Living documentation needs a place that stays current. A pack is the record of one conversation. |
| 3 | A scenario with an example id is generated and locked. A scenario without one is Gherkin-owned. Chosen by the builder. | A developer can still own a technical scenario, and existing projects change nothing. |
| 4 | One approval, of the examples. Generation stops with a plain question only on a finding that changes what a scenario proves. Chosen by the builder. | The scenarios are generated from approved text, so a second gate repeats the first. It keeps today's split between findings that matter to the product and findings that are technical. |
| 5 | The Gherkin is hidden from authors and approvers (H1). It is generated and committed. Chosen by the builder. | The smallest change that serves them fully. Removing it from the repo (H2) is a rework of the step layer and stays open. |
| 6 | Gherkin appears only under "For the developer:", and a developer can ask for it. Chosen by the builder, "at this moment". | The mechanism exists, and the harness rule that guards it is extended. |
| 7 | A config row `spec_source`, `examples` (default) or `gherkin`. Chosen by the builder. | A project that does not want the flow can keep today's. Existing features without an examples file stay Gherkin-owned in both cases. |
| 8 | The guards are mechanical: the ids, the literals and two hashes. No model judges them. My call. | The verdict must be repeatable. A model can generate, and a script checks. |
| 9 | The forced red on the actual side (#104) is the proof that a generated scenario watches what its example says. My call. | Nobody reads the generated scenario, so the red is the only evidence. |

## Existing users

A project that adopted an earlier version has `.feature` files and no examples file. Their scenarios have no example id, so they are Gherkin-owned and no guard touches them. Their own files with similar names, such as a hand-written `*.examples.md`, are not read unless they sit in the features folder and follow the shape. A new row is optional: `spec_source` is absent, and the default only applies to a feature that is discovered after the upgrade. Not covered yet: making an examples file from the existing scenarios of a feature.

## First run

In a fresh project with no config the default is `examples`. The first conversation ends with the examples file and one approval. The user is shown the examples and never the scenarios.

## Exclusions

- No removal of Gherkin from the repo and no tests in the project's own framework (H2).
- No model judging a scenario against its example. The checks are the ids, the literals and the hashes.
- No agent that runs the prose as a test (H3).
- No change to `implement` beyond what it reads: the scenarios are the same, and the steps are the same.
- No tool that makes an examples file from existing scenarios in this change.
- No example format other than the labelled line.

## Open, to look at in a trial

- The literal check when a value is written differently in the two places ("1 Nov" in the example, a date in the scenario). A rule or a normal form is needed.
- Regenerating the same example can give different wording, which makes the steps change. Regenerating only changed examples and reusing steps first should hold it, and it is not tested.
- An example that cannot be read as situation, action and outcome. The model asks a question then.
- Where the hash of the generated text is kept so that a formatting-only change does not fail it.

## Slices, in order

1. The examples file shape and the guard script (ids, literals, two hashes), with its spec. Repo tooling, no plugin text yet.
2. `design` generates from the examples, and `discover` writes the file. The `spec_source` row. The new text and its spec.
3. `deliver` with one approval, the report by example id, and the harness rule for Gherkin outside "For the developer:".
4. A trial on a real project, which decides the open points.

## Results

Slice 1 is done: `scripts/examples.sh` with `check`, `source-hash` and `scenario-hash`, and 28 scenarios in `specs/features/examples-guard.feature`. The findings are E-MISSING, E-ORPHAN, E-DUP (an id used twice in the examples file, or tagged on two scenarios), E-VALUE, E-SRC, E-GEN, E-NOHASH and E-NOFEATURE, and I-NONE when a project has no examples file. All 25 first scenarios failed before the script existed. 20 breaks in `tests/mutations/examples.tsv` are all caught. The first pass left four to look at: two broken break lines, a Windows line endings case that no scenario pinned (the hash was stamped by the same script, so it agreed with itself) and a break that is equivalent to the code (the first scenario of an id wins either way), which was dropped. A scenario for an id tagged on two scenarios was added, and with it a new rule, E-DUP.

The script is not yet copied by `install.sh` and no plugin text uses it. That is slice 2.

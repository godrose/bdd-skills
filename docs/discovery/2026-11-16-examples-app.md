# Discovery: an app where stories become checked examples

## Story

The people who own a story, approve it and build it work in three places today: the story in a tracker, the test cases in a case manager, the automation in a repo. Nobody sees the whole picture, and the common language they are offered is Gherkin. The builder wants one place where the current version of a story sits with its context, where examples are generated from it in domain words, checked against the existing examples, and approved once as the scope. The Gherkin and the automation are generated behind it and stay out of sight of the approver.

Success, in the builder's words: people do not need to invent a new language, they use the shared space to collaborate, most of the work is done autonomously, and people only approve the scope.

This continues `2026-11-15-examples-source.md`. That pack makes labelled examples the source of the spec inside the repo. This one gives them a place where the people who approve them actually work.

## Prior art

AssertThat, a Jira plugin. It keeps feature files next to the story, syncs them with the repo and shows the results in Jira. The builder used it, and the friction was the Gherkin: people had to write it to use the tool. The shape stays (examples next to the story, a link to the repo, the results in one view). The common language changes from Gherkin to labelled examples.

## Existing behavior

- `discover` turns a story into questions and agreed examples in a conversation in the terminal. `deliver` asks for the approval there too.
- On `feat/examples-source`, an examples file `<feature>.examples.md` holds the labelled examples, and `scripts/examples.sh check` guards the ids, the values and two hashes.
- No command compares a new example with the existing ones. `design` audits the reuse of steps, which is the closest thing.
- Nothing runs outside a terminal session, and nothing shows results by example.

## The whole app, in slices

| Slice | What works | Depends on |
|-------|------------|------------|
| B | Example authoring with checks: a story in, examples out, checked for contradiction, overlap and value, one approval of the scope writes the examples file as a PR | Nothing beyond slice 1 of the examples source |
| C | The autonomous pipeline: an approved examples file becomes hidden Gherkin, step code and a CI run, with no person in between | Slices 2 and 3 of the examples source |
| A | The results view: every example with its latest run and the open PR | Results reported by example id |
| D | The reviewing agent: each run is read, and a suspicious pass becomes "passed, needs attention" | Real runs, so C first |

The builder chose B first. C goes on in parallel on `feat/examples-source`, where its slices are already planned. A and D follow. Only B is specified below. The decisions about A and D are recorded so that they are not asked again.

## Agreed examples (slice B)

The domain in the examples is a library. The existing example is E3 of the late-loans feature: "A book borrowed on 1 Nov and returned on 20 Nov is late, and the fine is 5."

| # | Situation | What happens |
|---|-----------|--------------|
| B1 | Someone opens a story | The app shows the current text of the story, the existing examples related to it and the open PR that works on it. |
| B2 | Examples are generated from the story | Each is a labelled example in domain words with concrete values. The app shows its split into situation, action and outcome next to it. |
| B3 | The split is wrong | The person edits the split or the text. The split is confirmed once, when the scope is approved. |
| B4 | A new example has the same situation and action as an existing one and a different outcome: "borrowed 1 Nov, returned 20 Nov, no fine" | Contradiction. The two are shown side by side, and the approval is blocked until a person picks one: the existing example changes (recorded as a reversal with its reason), the new one changes, or the situations differ and the split is corrected. |
| B5 | A new example states a rule that disagrees with an existing one without sharing a value: "loans up to 21 days are on time" | The model proposes a contradiction with E3. It blocks the approval like B4 until a person resolves it or dismisses it. |
| B6 | A new example has the same situation and outcome in other words: "returned 19 days after borrowing, fined 5" | Overlap, naming E3. The person drops it or keeps it. |
| B7 | A new example tests the same rule with values in the same range: "borrowed 1 Nov, returned 22 Nov, fined 5" | Overlap, naming E3 and the rule. |
| B8 | A new example pins where a rule switches: "returned on day 14, no fine" | Not an overlap. It provides value: a boundary. |
| B9 | A new example pins something no example pins yet | It is marked as providing value and says what it pins: a rule, a boundary, an outcome or a situation. |
| B10 | A new example uses a word the vocabulary has another word for: "client" where the existing examples say "member" | The app proposes the vocabulary word. The person accepts it, or adds the new word as a term of its own. |
| B11 | The scope is approved | One approval. The app writes `<feature>.examples.md` on a branch and opens a PR in the repo. Nothing is written before it. |
| B12 | The repo has no examples yet | No checks against existing examples, and every example provides value. The vocabulary starts from the words of the story. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | One place holds the story, its context and its examples. The story's context is its related existing examples and its open PR. Chosen by the builder. | The people who approve the scope do not work in the repo, so the readable layer has to live where they work. |
| 2 | The app can be deployed anywhere and connects to where the examples are stored, a GitHub repo or a case manager such as Qase. It should not matter which. Chosen by the builder. | Teams keep their test cases in different places. |
| 3 | The common language is the labelled example. Gherkin and automation are generated and hidden from the approver. Chosen by the builder. | It is what failed in AssertThat. It is decision 5 of the examples-source pack, carried into the app. |
| 4 | A new example is checked for contradiction, overlap and value. Value means it pins something new: a rule, a boundary, an outcome or a situation. Chosen by the builder. | These are the problems an approver cannot see across many stories. |
| 5 | Each example is split into situation, action and outcome in the vocabulary. A model proposes the split, and a person confirms it once, at the approval. The comparisons after the split are mechanical. The split follows fixed rules: the action is one of a fixed list kept in the vocabulary, a value is short and normalized (an amount with its currency, a status as written, no sentences), and a fact every existing example shares is background and is dropped by the script before comparing. Two splits are compared on the terms both carry, when they share enough of their situation, because a plain example splits shorter than a long scenario. My call, from the spike. | It keeps the rule of the examples source that a verdict is repeatable. The only judgment is the split, and a person owns it. |
| 6 | A contradiction blocks the approval until a person answers it, whether a comparison found it or the model proposed it. An overlap and a missing value only inform. My call. | A contradiction left in the scope makes one of two examples false. An overlap costs only a duplicate test. |
| 7 | Most of the work is autonomous, and people approve only the scope. Chosen by the builder. | The success criterion. |
| 8 | One view shows the runs of all examples. An agent reads each run and highlights suspicious deviations. Chosen by the builder, for slices A and D. | People approve the scope and do not read the automation, so the trust has to come from looking at the results. |
| 9 | An example the agent flags is "passed, needs attention". A team setting decides whether it counts as passing or failing, and passing is the default. Chosen by the builder. | A team decides how much it trusts the agent. |
| 10 | The setting changes only the status in the view and the PR check, never the test run's own result. A flag is kept with its run and is not judged again unless the run changes. My call. | The test verdict stays mechanical, and the same run always shows the same status. |
| 11 | A flag names its owner. A suspect test goes to the developer, a suspect behavior goes to the approver as one plain question, and an unclear one goes to the developer first. My call. | It is the split `deliver` already makes between technical findings and product decisions. |
| 12 | Slice B first. Chosen by the builder. B is a web page over one GitHub repo. My call. | B is the only part no existing tool does, and its assumption (a model can split examples well enough for mechanical checks) is the riskiest. A GitHub repo needs no adapter beyond the examples file of the examples source. |
| 13 | The app lives in a repo of its own, private for now. This repo keeps the contract: the examples file shape, the hash rules and `scripts/examples.sh`, with their spec. The app runs the script at a pinned commit and does not reimplement it. Its repo borrows this repo's suite setup (Cucumber and the mutation runner). Until `feat/examples-source` reaches `main`, the app pins a commit of that branch. Chosen by the builder, on my proposal. | The plugin install, its release process and its CI stay free of a web stack, and an app that fails its trial is archived without undoing anything here. One guard keeps the verdict repeatable. |
| 14 | The confirmed split is kept in `<feature>.split.json` beside the examples file: one entry per example id with the situation, the action, the outcome, the vocabulary terms used and the source hash it was confirmed against. When the example's source hash no longer matches, the split is stale and must be confirmed again. The examples file keeps its slice 1 shape. Chosen by the builder, on my proposal. | The examples file stays the plain-words document people read, and the split is machine data the app shows in plain words. A stale split is caught by a script, not by a reader. Keeping it in the repo keeps the comparisons repeatable from the repo alone. |
| 15 | One vocabulary per repo, `vocabulary.md` at the root of the features folder: each term with its meaning and the words to avoid. The app proposes additions from new splits. New terms and rejected words ride on the one approval of the scope, so the approver owns the file and a developer proposes changes by PR. Every term in a split file must be in the vocabulary, which a script checks. On an existing repo the first run proposes a vocabulary from the existing examples, or from the step text when there are only scenarios, approved once. Chosen by the builder, on my proposal. | The vocabulary is shared across features, so it lives once. The file remembers decisions such as "not client", and the proposals keep its upkeep small. No second gate. |
| 16 | Gherkin-owned scenarios take part when they are related to the story, found through the vocabulary. They are split when needed and confirmed with the scope. Each confirmed split goes into the split file, keyed by scenario id and the scenario's hash, so a hand edit makes it stale. Every check result names its coverage, such as "checked against 4 examples and 2 confirmed scenarios; 3 related scenarios are not confirmed yet". The model may propose a contradiction with an unconfirmed scenario, and it blocks until a person answers it, as decision 6 says. Chosen by the builder, on my proposal. | The cost grows with use and not at adoption. The app never claims more than it checked. |
| 17 | B opens its PR as a draft, with the approval recorded on it. The slice 1 guard fails it with E-MISSING until slice C adds the generated scenarios to the same PR, which then becomes ready. The guard gets no "approved, not generated yet" state. My call. | The guard cannot tell a scenario never generated from one that was deleted, so such a state would weaken it. A red guard on a draft is the true state. In a trial of B, the checked and approved scope is the result. |
| 18 | A story comes in from a GitHub issue, whose open PR is found through GitHub's link between issues and PRs, or as pasted text, where no PR is shown and the person can pick one. Other trackers are adapters for later. My call. | Both cost little on a GitHub repo, and decision 2 keeps the other trackers open. |
| 19 | The stack is a web app in TypeScript with a server that holds the model key, talks to GitHub and runs `scripts/examples.sh` in a container. A native app (Rust and Tauri) may wrap the same UI later. Chosen by the builder, on my proposal. | The approver is the first user and needs a link, not an install. The suite setup of this repo carries over. A container deploys anywhere. |

## Existing users

The app is new and nobody has it. A repo that uses the plugin today has `.feature` files and maybe examples files. The app reads the examples files and writes only through a PR, so nothing in the repo changes without a review. Gherkin-owned scenarios are not changed. Whether they count as existing examples in the checks is open.

## First run

The app is connected to a repo with no examples file. A story is pasted, examples are generated, no checks against existing examples apply, and the vocabulary starts from the words of the story (B12). The approval opens the first PR.

## Exclusions

- No Gherkin in front of the approver, in B or later.
- No generation of scenarios or step code in B. That is slice C.
- No results view and no reviewing agent in B. Those are slices A and D.
- No case manager adapter (Qase) in B. Decision 2 holds for the design, and B builds only the GitHub repo.
- No replacement of the tracker in B. The story is pasted, or read from a GitHub issue.
- No model verdict that blocks without a person: a proposed contradiction blocks until a person answers it.

## Open, to learn in a trial of B

- Whether a careful review confirms as many splits as the quick one in the spike (see Results).
- Whether the vocabulary finds the related examples and scenarios, and how many it misses.
- How long a check takes and what it costs per story, with the related scenarios split on the way.
- Whether a proposed rule-level contradiction (B5) is right often enough that blocking on it does not annoy. The spike tried only contradictions that a comparison finds.

## Results

A throwaway spike, on 2026-11-20, took 22 Gherkin-owned scenarios from a private payments project (long UI scripts with tables) and ran the split and the checks on them, with no UI. The scenarios and their data stay out of this repo.

- **Vocabulary.** One model call proposed 34 terms from the 22 scenarios, each with its meaning and the words to avoid. They read as domain words, such as a customer for what the steps call a kiosk user.
- **Free splits cannot be compared.** The first pass filed the same fact under different terms and wrote values as sentences, so two scenarios that differ by one value did not match. With the rules now in decision 5, the second pass matched them.
- **Background.** The script found the facts that every scenario shares (test data such as a fixed device and language) and dropped them. The model did not need to.
- **Exact matching is too strict.** Three seeded plain examples, a contradiction, a duplicate in other words and a new outcome, were all missed by comparing whole key sets, because a plain example splits shorter. Comparing on shared terms caught the contradiction (an amount that differs) and the duplicate.
- **False contradictions have one cause.** The seeded new outcome was flagged as a contradiction, because its split left out the condition that decides it (the provider rejects the payout). Among the 231 pairs of existing scenarios, one pair was flagged for the same reason. It is the safe direction: it blocks, and the person adds the condition to the split, which is resolution three of B4.
- **Real findings.** Two near-duplicates (the same payout reached through two providers, differing only in the customer's contact), a rule tested three times with other countries, a scenario that checks less than its twin (no amount), and a scenario whose own tables disagree on an amount, which the model raised as a question.
- **Confirmation.** The builder confirmed all 22 splits in a quick review. One of them misses the deciding condition above, so 21 of 22 stand as they are.
- **Cost.** 23 model calls, six at a time, in a few minutes.

What it changes: decision 5 gets its rules. The split confirmation is where a missing condition is added, so it stays a required step and not a formality. The plain sentence of an example should be written after the background facts are dropped, or it repeats test data.

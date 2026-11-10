# Discovery: a scripted flow run for `bdd:discover`

Input: the six single-turn eval cases, known gaps G7 and G9, the headless trials of `discover` run by hand with `claude -p` and `--resume`, and a discovery dialogue with the builder, one question at a time. The builder acts as product manager, developer and solo developer here: the plugin is the product and the method is applied to itself.

## Story

The plugin is a set of commands. Text tests pin sentences in them, and six eval cases run one prompt each and stop at the first approval gate. Nothing shows how a command behaves across a whole conversation. The trials that did were run by hand. The builder wants a scenario of a command to count as passing only when a real headless run showed it. This pack covers the first such layer, for `discover` only.

## Existing behavior

- `claude plugin eval` runs one prompt per case. Its help shows no option for scripted follow-up replies. Every case in `evals/` ends at the first gate.
- Graders: `tool_used`, `regex` and `file_exists` are stable. The `llm` judge needs Sonnet. `file_exists` sees created files, not edits.
- A run of a single-turn case took 17 to 40 seconds and cost about 1 cent notional with Haiku. The cost of a multi-turn run is not known.
- The nightly evals are switched on and green. A case with a strict grader (G9) can still fail without a regression.
- The hand trials used `claude -p` with a plugin folder, a read-only tool grant, a throwaway config and `--resume` for later turns. They showed rule breaks that text tests cannot see: two questions in one message, an internal step name shown to the product manager, and a code question put to a product manager.
- The plugin folder cannot hold scripts or fixtures (directory policy). Scripts and evals live at the repo root.

## Agreed examples

- **E1** A run starts `/bdd:discover` with a story on a fixture project. A small model plays the product manager from a short persona card and answers each question. The run ends when the pack says "ready" or "not ready", or at a turn cap of 12.
- **E2** Every reply and every assistant message is saved in a run folder, so a failed run can be read again.
- **E3** The rules are counted on the transcript. Look first: the first message states what exists before it asks. One question: one per message to the product manager. Plain words: findings carry no file paths or code names (a judge checks this one). Source: a value the system sets is stated "from code". Pack end: the end says "ready" or "not ready" with the reason.
- **E4** After the run the project folder is compared with the fixture. A new or changed file outside the pack folder is a break.
- **E5** Fixture A is a small made-up project with one scenario that covers part of the story and one value the system sets by itself. Its run checks that Step 0 reports what exists.
- **E6** Fixture B has no scenarios and no screens. Its run checks that Step 0 says it found nothing, and that a one-person founder persona gets the A/B/C question and can end "ready" with a listed assumption.
- **E7** The report gives each rule's count out of 3 runs, with the breaks and the replies beside them, plus time, usage and turns. It gives no pass or fail.
- **E8** The harness runs only by hand. It is not in `tests/run.sh` and not in the nightly.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Which command first? | `discover`. | The shortest flow. It only reads, needs no test runner in the fixture, and its shape is known from the trials. `deliver` (G7) follows once the cost is known. |
| 2 | What does a pass prove? | The rules the command states were followed. Not that the questions were good. | Judging the questions needs expert readers. Our trials showed that the rule breaks are what a script can catch. |
| 3 | Where do the replies come from? | A small model plays the product manager from a persona card. Every reply is logged. | A fixed list answers questions that the run may not ask, as the third-project runs showed. A persona card is plain text anyone can change. |
| 4 | When does it run? | By hand first. The nightly is added after the cost and the variance are seen. | No cost figure exists for a multi-turn run, and the nightly already has one noisy grader (G9). |
| 5 | What does it run on? | Two made-up fixtures in the repo: A with something to find, B with nothing. | Step 0 has two paths. One fixture would test one. Real projects cannot live here and cannot be held identical. |
| 6 | What counts as a pass? | Nothing at first. Counts out of 3 per rule, breaks listed. A threshold is chosen from the data. | A threshold chosen before any data is a guess, which is how G9 arose. |
| 7 | Where does it live? | At the repo root under `evals/`, not in `plugin/`. It reuses `claude -p` with `--resume`. | The directory policy keeps scripts out of the plugin folder. No new tool is needed. |
| 8 | Which models? | Haiku plays the product manager. Sonnet judges plain words. The model under test is the default. | The eval notes found the Haiku judge weak. The product manager's role needs only short answers. |

## Existing users

- Nothing changes in a user's project or in the plugin. The plugin folder is untouched.
- The harness is a maintainer tool in this repo. It is not installed with the plugin.

## First run

A maintainer runs one script with a fixture name and a run count. Without a Claude login, or with no `claude` on the path, it says so and stops. It never writes outside its run folder.

## Exclusions

- Judging whether the questions were good. Reason: needs expert readers.
- Flows of `design`, `implement`, `deliver` and `run`. Reason: first learn the cost and variance on `discover`.
- The nightly and CI. Reason: see decision 4.
- A fixed list of replies as a fallback. Reason: decision 3.
- Real projects as fixtures. Reason: decision 5.
- A pass threshold. Reason: decision 6.

## Open

- The cost of one multi-turn run and the variance between runs: the first spike measures both.
- Whether the persona model's replies vary enough to change what the run asks. The logged replies show it.

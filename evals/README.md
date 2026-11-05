# Evals

A spike with `claude plugin eval`. Five single-turn cases. Four come from failures found in a real trial. `design-lint-draft` checks the lint step added from the cross-project review (see `docs/discovery/2026-11-05-lint-in-design-and-layered-steps.md`). Each ends at the command's first approval gate. See `docs/discovery/2026-11-05-eval-spike.md`.

| Case | Command | What it checks |
|---|---|---|
| `init-audit` | `/bdd:init --detect` | Reports an existing path that does not resolve. Writes nothing. |
| `design-vague-ac` | `/bdd:design` | Flags "finished" as vague. Shows scenarios in full. No feature file yet. |
| `triage-approval-gate` | `/bdd:triage` | Asks for approval. Writes no record or feature file first. |
| `run-zero-tests` | `/bdd:run` | A run of zero tests is not a pass. |
| `design-lint-draft` | `/bdd:design` | Lints the draft before showing it. Acts only on findings in the draft, reports the old one untouched, and leaves no `.bdd-draft-*` file. |

Each case copies its `fixture/` into the run folder with `scaffold.sh`, so every run starts in the same state.

## Run it

Runs are full Claude Code sessions on your own login. They draw on your plan's usage limit, so start small. A first pilot is one run per case, no baseline arm and a small model:

```bash
claude plugin eval . --scaffold --runs 1 --ablation none --model haiku --judge-model sonnet --no-publish \
  --allow-tools Write Edit "Bash(sh ./fake-test.sh:*)"
```

- `--scaffold` runs the cases' `scaffold.sh` as you. Use it only on cases you wrote.
- `--no-publish` keeps the report local. It holds prompts and outputs.
- Drop `--runs 1` for the default of 3 runs, and drop `--ablation none` to add the no-plugin baseline. Both multiply the usage.
- `evals/results/` is ignored by git.

`design-lint-draft` runs the lint row, writes a temp draft file and deletes it. The agent chains commands (`cd x && sh ./fake-lint.sh`), and narrow `Bash(...)` grants deny them, so the lint step never runs. Give it plain `Bash`, only for this case:

```bash
claude plugin eval . --scaffold --runs 1 --ablation none --model haiku --judge-model sonnet --no-publish \
  --case design-lint-draft --allow-tools Write Edit Bash
```

The grant lets the agent run any shell command as you. Use it only for this case, which you wrote, and never together with a glob that selects other cases. The run happens in a throwaway directory with its own home.
- The evals are not part of `bash tests/run.sh`. `tests/test_evals.sh` only checks the folder's structure.

## What the spike found

Run on 2026-11-05 with Claude Code 2.1.318, `--model haiku`, one run per case, no baseline.

- **It works end to end.** The plugin loads from the repo path. The slash commands fire in a headless run. `scaffold.sh` copies the fixture into the run folder. All four cases ended cleanly at the first approval gate.
- **Cost.** Each run took 17 to 40 seconds and the tool reported about 1 cent per run (3 cents with the Sonnet judge). The owner's plan usage meter did not move after a pilot of about 8 runs. The reported dollar figure is notional on a monthly plan.
- **Graders.** `regex`, `file_exists`, `tool_used` and `llm` all worked. The deterministic ones are stable. `file_exists` sees only files created in the run, not edits to existing files, so "wrote nothing" is checked as "created nothing".
- **The default judge is weak.** The default `llm` judge (Haiku) voted FAIL three times on a design answer that plainly met the rubric. With `--judge-model sonnet` the same grader passed 3 of 3. Use the Sonnet judge, write rubrics as concrete claims, and prefer a `regex` or `file_exists` check wherever one can do the job.
- **Tools need grants.** A case that must write, or run a command, needs `--allow-tools`. Without it the agent adapts and says so (the design run said Bash was denied and read the files instead), so the run is less faithful to real use.
- **`--case` takes one glob.** Repeating it keeps only the last one.
- **No plugin bug found.** The runs showed no plugin defect. In the design case the plugin flagged "finished" as an open assumption on its own, and its step audit noticed that the existing step bodies are empty.

- **Full run: 4 cases, 3 runs each** (Haiku agent, Sonnet judge, no baseline): 418 seconds and about 23 cents notional. `design-vague-ac`, `init-audit` and `run-zero-tests` scored 1.00 on all 3 runs. `triage-approval-gate` scored 0.87 at first, because the rubric said Lee's "ok" is not agreement to the two rules, while the agent (correctly) tied it to the out-of-scope decision. After rewording the rubric to that property it scored 1.00 on 3 of 3.
- **A rubric must state the property you mean.** Both rubric fixes in this spike came from a vaguely worded claim, not from the plugin. Read the agent's output before blaming either side, and say in the PR when a rubric is reworded.

- **Baseline run: no difference yet.** `design-vague-ac` with and without the plugin, 3 runs per arm, scored 1.00 on both arms (delta 0.00). The plain agent also flagged "finished" and wrote full Gherkin, because the prompt asks for scenarios and points at the statuses file. These graders do not separate the plugin from a plain agent. To measure what the plugin adds, grade what only it does: the per-step reuse audit, the `@pending` tag in `specify-only` mode, and the empty-step-body warning.

- **Baseline with plugin-only graders: delta +0.48.** After adding three graders taken from `design.md` (a per-step reuse audit, an "Asserts" column in it, and the `@pending` tag in `specify-only` mode), `design-vague-ac` scored 1.00 with the plugin and 0.52 without it, over 3 runs per arm. Read this with care. Those three are checks for the plugin's own artifacts, which a plain agent cannot know about, so the delta shows that the plugin produces its required output. It does not show that the plugin's answers are better. One plain run also failed to flag "finished" as an open question, which is a small sign of better quality, but 1 of 3 is not a measurement.

Not measured: the baseline for the other three cases, and any comparison of answer quality that a plain agent could also pass.

- **`design-lint-draft`: 5 of 7 runs scored 1.00** (Haiku agent, Sonnet judge, no baseline, plain `Bash` grant). The first batch of 3 scored 1.00, 0.75 and 0.88. A second batch of 4 scored 1.00 each. I could not read the misses: they did not reproduce and the first sandboxes were not kept. They are probably variance from the small model, which I have not proven. With narrow `Bash(...)` grants the same case scored 0.71, because the agent's chained commands were denied and the lint step never ran (the plugin warned and went on, as designed). Two patterns were reworded from exact phrases to the property, because the agents stated it in other words and the fake linter prints "no findings" only when the whole folder is clean.

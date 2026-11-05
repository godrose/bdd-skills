# Evals

A spike with `claude plugin eval`. Four single-turn cases, each from a failure found in a real trial. Each ends at the command's first approval gate. See `docs/discovery/2026-11-05-eval-spike.md`.

| Case | Command | What it checks |
|---|---|---|
| `init-audit` | `/bdd:init --detect` | Reports an existing path that does not resolve. Writes nothing. |
| `design-vague-ac` | `/bdd:design` | Flags "finished" as vague. Shows scenarios in full. No feature file yet. |
| `triage-approval-gate` | `/bdd:triage` | Asks for approval. Writes no record or feature file first. |
| `run-zero-tests` | `/bdd:run` | A run of zero tests is not a pass. |

Each case copies its `fixture/` into the run folder with `scaffold.sh`, so every run starts in the same state.

## Run it

Runs are full Claude Code sessions on your own login. They draw on your plan's usage limit, so start small. A first pilot is one run per case, no baseline arm and a small model:

```bash
claude plugin eval . --scaffold --runs 1 --ablation none --model haiku --no-publish \
  --allow-tools Write Edit "Bash(sh ./fake-test.sh:*)"
```

- `--scaffold` runs the cases' `scaffold.sh` as you. Use it only on cases you wrote.
- `--no-publish` keeps the report local. It holds prompts and outputs.
- Drop `--runs 1` for the default of 3 runs, and drop `--ablation none` to add the no-plugin baseline. Both multiply the usage.
- `evals/results/` is ignored by git.
- The evals are not part of `bash tests/run.sh`. `tests/test_evals.sh` only checks the folder's structure.

# Discovery: a spike with `claude plugin eval`

## Story

Almost every plugin failure so far was found by trying the plugin on a real project, then fixed by a text rule and a text-assertion test. Those tests prove the rule text exists. They do not prove the model follows it. `claude plugin eval` (Claude Code 2.1.318) can run cases against the plugin and grade the result. The spike finds out what it can and cannot grade here, with four cases drawn from past failures. Success means learning that, not coverage.

## History used

- Discovery packs from the .NET trials: design assumptions, the Then-assertion check, zero tests ran, the `prepare` row, verifier selection, step batch, framework-neutral implement.
- The bdd-netcore dogfood doc and the demo findings (`evidence/plugin-findings.md`).
- The only decision log is the demo's. It holds no failures.

## What the tool is (from `claude plugin eval --help` and a scaffolded case)

- Cases live under `evals/`. A case is a `case.yaml`, or a `prompt.md` with `graders/*.md` beside it.
- A prompt header has `max_turns` and `allowed_tools`. A grader has `type: llm` and a `weight`.
- `--ablation with-without` runs a no-plugin baseline and reports the score delta.
- `--runs`, `--threshold`, `--max-cost-usd`, `--no-publish`, and `--scaffold` (runs each case's `scaffold_script`, which executes author-supplied bash).
- Not verified: other grader types such as `tool_used`, a check that a file was or was not written, and scripted multi-turn replies. The spike must find these out.

## Cases

| Case | Past failure | Fixture | A pass looks like | Grader |
|---|---|---|---|---|
| A. `init --detect` audit | Existing wrong values were never reported | A config with one path that does not exist | Names the bad row and path. Writes nothing. Ends with the "Not checked" line. | Text match, plus an LLM check for "wrote nothing" |
| B. `design` vague AC | "Finished" was not flagged | One feature and the AC "a finished experiment can be deleted" | Flags "finished" before designing. Shows every scenario in full. | LLM |
| C. `triage` approval gate | Nothing may be written before approval | The demo thread and an empty decisions dir | Asks per item. Used no write or edit tool. | `tool_used`, if it exists |
| D. `run` zero tests | A run of zero tests read as green | A fake test command that prints "No test matches" and exits 0 | Does not report PASS. Says nothing ran. | Text match |

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Scope | Four single-turn cases, each ending at the first approval gate. | The rules that matter most sit at the gates. Multi-turn support is unverified. |
| 2 | Which cases | A, B, C, D. `discover` existing behavior is out. | A and D are deterministic, C tests tool use, B tests LLM judgment. `discover` overlaps with B. |
| 3 | Fixtures | Committed under `evals/fixtures/<case>/`, copied in by each case's `scaffold_script`. Run with `--scaffold`. | Clean, reviewable, repeatable starting states. We author the scripts. |
| 4 | Results | `evals/results/` goes into `.gitignore`. Runs use `--no-publish`. | Results are run output. The repo is private and the report holds prompts. |
| 5 | Cost and gating | 3 runs per case, a 5-dollar cap on the whole run, no pass threshold. | We do not know yet what a score means. A gate would be a guess. |
| 6 | Baseline | Keep the with-without ablation. | It shows whether the plugin beats a plain agent. |

## Existing users

None affected. `evals/` is a new folder in the repo. The plugin install does not use it. Check that `install.sh` and the plugin packaging do not copy it into user projects.

## First run

A contributor runs `claude plugin eval .` from the repo root and gets a local report. They need the `--scaffold` flag and must trust the plugin. The README says nothing about it until the spike ends.

## Candidate exclusions (all confirmed)

1. Multi-turn cases and any `implement` or `reconcile` case.
2. Coverage of all commands, `discover` and the verifier agent included.
3. CI. `tests/run.sh` does not call the evals.
4. Real frameworks in the fixtures.
5. Publishing the report.
6. Replacing the text-assertion tests.
7. A pass threshold.

## What the spike must find out (not open questions)

- Is there a grader for tool use and for files written? If not, how far does an LLM grader go?
- Does a prompt that asks for approval end the run cleanly, or does the agent keep going?
- Do `--ablation` scores differ clearly with and without the plugin?
- What does a run cost, and how much do three runs vary?

## Readiness

Ready for `bdd:design`. No open questions. Every exclusion is confirmed.

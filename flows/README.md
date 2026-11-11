# Flow runs

A flow run starts `/bdd:discover` on a small made-up project as a whole conversation. A small model plays the product manager from a persona card. The rules the command states are counted on the transcript. The report gives counts and breaks, no verdict. See `docs/discovery/2026-11-10-discover-flow-runs.md`.

```bash
bash flows/run.sh --fixture a            # something to find: one scenario, one value the system sets
bash flows/run.sh --fixture b --runs 3   # nothing to find: no scenarios and no screens
```

- Run it by hand. It starts real sessions and uses your plan's limit. It is not part of `tests/run.sh` and not in the nightly.
- Options: `--runs` (default 3), `--turns` (cap, default 12), `--persona pm|founder`, `--out DIR`. Results go to `flows/results/`, which git ignores.
- The run folder holds every message (`turn-NN-assistant.txt`, `turn-NN-pm.txt`), `meta.json`, `rules.tsv` and a copy of the project.
- `tests/test_flow.sh` tests the harness with a fake `claude`. It checks the harness, not the model.

## Flow runs for `deliver`

`/bdd:deliver` runs through two approvals, writes scenarios and steps, runs the tests, looks at the result and writes a report. See `docs/discovery/2026-11-11-deliver-flow-runs.md`.

```bash
bash flows/run.sh --command deliver --fixture c --story 1 --runs 1   # a clean run: every example passes
bash flows/run.sh --command deliver --fixture c --story 2 --runs 1   # one example cannot be checked: the report must say so
```

- Fixture `c` has a working test runner. The harness installs it once into `flows/results/cache/`, keyed on a hash of the lockfile. The first run needs the network. The model is allowed `npm test` and `node src/show.js`, which prints the loans page built from `data/loans.json` or from another loans file under `data/`, so step 5 can look at the real page. It has no install command.
- The turn cap is 30. The persona is `approver`, who answers "Approved" at each gate.
- Rules counted on top of the `discover` ones: no feature file before the second approval, an approval asked at most twice, one report line per agreed example with the "Not checked" section exactly when something was parked, and an example named in the "Not checked" section never marked passed, and no example reported as passed when the saved test output (`test-output.txt`) shows a scenario that did not pass. Limit: the last check does not match an example to its scenario. It breaks only when every example is passed and the output shows a gap.
- Compare two reports to see what moved: `bash flows/run.sh --compare REPORT_1 REPORT_2`. It prints the counts side by side and marks the rules that moved. It gives no verdict. Any saved `report.md` is a baseline.

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

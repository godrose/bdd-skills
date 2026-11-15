# Discovery: the flow harness records the calls and counts the build order

## Story

`bdd:deliver` has a `build_order` row (`all-first` or `per-scenario`) and a flag `--build-order`. The flow harness keeps only the text of each turn, so a run cannot show which order the agent followed. The follow-up named in `2026-11-15-implement-test-side.md` is to save the calls of each turn and add a rule that counts the order.

## Existing behavior

- `flows/run.sh` asks each turn for `--output-format json` and keeps the `result` text and the cost.
- `flows/rules.ts` counts rules on the turn texts, the project diff and the saved test output. It gives counts and breaks, no verdict.
- The test stand-in `specs/fixtures/fake-claude.sh` prints one JSON object with `result` and `total_cost_usd`.
- Recorded runs of 2026-11-11 to 2026-11-15 hold no calls.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| E1 | A deliver run | Each turn is run with `--output-format stream-json --verbose`. The raw events are saved as `turn-NN-events.jsonl`, next to `turn-NN-assistant.txt`. The text and the cost are read from the `result` event, as before. |
| E2 | `build_order` is `all-first` (flag, row or default), and at the first edit of application code no new scenario was undefined in the last run of the whole suite | The rule `build-order` is held. |
| E3 | The same, and one or more new scenarios were still undefined | The rule is broken. |
| E4 | `build_order` is `per-scenario`, and one or more new scenarios were still undefined at the first application edit | Held. |
| E5 | The same, and none was undefined | Broken. |
| E6 | The expected order | From `--build-order` in the story text, else from the `build_order` row in the fixture's config, else `all-first`. It is saved in `meta.json` with the count of new scenarios. |
| E7 | No application edit was made, or fewer than two scenarios are new, or the run holds no events, or no run of the whole suite came before the edit | The rule is not counted. A recorded run of the older kind is not a break. |
| E8 | An edit of a file under the features folder, the steps folder, `docs/` or `data/` | Not an application edit. The folders come from `features_dir` and `steps_dir` in the project's config, with `features` and `steps` as defaults. |
| E9 | The report of the harness | Shows the rule `build-order` like any other. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | The measure is how many of the new scenarios have steps and have been run red at the first application edit. Agreed by the builder. Counted as the new scenarios that are still undefined in the last run of the whole suite. | The two orders differ at that moment: with `all-first` the steps of every new scenario exist, with `per-scenario` only the first scenario's steps do. |
| 2 | The source is `--output-format stream-json --verbose`. The stand-in `fake-claude.sh` prints events and then a `result` event. The product manager call stays `--output-format json`. Chosen by the builder. | A documented output, and no dependence on where Claude Code keeps its files. |
| 3 | The raw events are saved, not a summary. My call. | Nothing is lost, and a later rule can read what it needs. |
| 4 | No undefined scenario means `all-first`, and one or more means `per-scenario`. Reverses my first call, which counted failures: two or more failed meant `all-first`. | A real `per-scenario` run had two scenarios fail at once, because they share steps, and the rule broke although the agent followed the order. A scenario that already passed before the build, as E3 of the fixture's story does, never fails either, so failures are a poor stand-in. |
| 5 | The rule is counts only, like the others: a held or broken line with the numbers in its detail. | The harness gives no verdict. |
| 6 | Mutation breaks for the new lines go in `tests/mutations/flows.tsv`. | The approach review. |

## Existing users

None. The harness is repo tooling and the plugin is not touched. A run folder of the older kind has no events, and the rule is not counted for it.

## First run

`flows/run.sh --fixture c --command deliver --story 1` leaves `turn-NN-events.jsonl` files and a `build-order` line in `rules.tsv`.

## Exclusions

- No change to the plugin text.
- No rule for the order of calls in `discover`.
- No verdict on the quality of the build.
- No change to the product manager call.

## Limits

- An agent that runs one scenario at a time in `all-first` shows one failure per run, and the rule calls it broken. The count is of failures in a single test run, the highest one before the first application edit.
- Two failures and one failure are the only two cases it tells apart.

## Result of a real run and of the breaks

Fixture c, story 1, `deliver`, one real run with the stream output: 4 turns, 108 seconds, all ten rules held, one `turn-NN-events.jsonl` per turn. The events hold assistant, user, system, rate-limit and result events, and the result event carries the text and the cost as before. The test runs before the first application edit showed 3 and then 4 failed scenarios, so the first form of `build-order` read "expected all-first: 4 failed of 4 new scenarios at the first application edit" and held.

A second real run, `--build-order per-scenario` on fixture c (4 turns, 134 seconds), broke the first form of the rule: "expected per-scenario: 2 failed of 5 new scenarios at the first application edit". The agent did follow the order. It wrote steps for the first scenario, ran it, built the feature, and went back to the steps for the rest. But two scenarios shared a step, so both failed at once, and the last whole run before the first edit read `6 scenarios (2 failed, 3 undefined, 1 passed)`. The count of failures was the wrong stand-in for "how many new scenarios have steps". The rule now counts the undefined ones (decision 4). Replayed on the saved events, the `all-first` run reads "0 of 4 new scenarios had no steps" and holds, and the `per-scenario` run reads "3 of 5 new scenarios had no steps" and holds.

The 16 breaks of `tests/mutations/flows.tsv` for the new lines are all caught. The first pass of the first form left three to look at: a gap (no scenario with exactly two failures under `per-scenario`) and two faulty break lines. The first pass of the second form left two gaps: no `all-first` scenario with exactly one undefined, and no scenario whose no-edit run would have broken the rule if it had been counted. Both are pinned now.

Limit: a run of the whole suite is one that reports at least as many scenarios as the new ones. A run by tag over fewer scenarios is not seen, and a run with none of the whole suite before the edit is not counted.

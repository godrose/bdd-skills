# Discovery: the flow scripts move from Perl to TypeScript (option A)

Input: a read of `flows/rules.pl` (105 lines), `flows/report.pl` (35), `flows/compare.pl` (17), `flows/run.sh`, `tests/mutations/flows.tsv`, `specs/steps/flow-setup.steps.ts` and `flows/results/` (15 recorded runs, 120 assistant messages, git-ignored). The maintainer asked earlier why Perl was used. No reason was recorded. Three questions were asked, one at a time.

## Story

A maintainer who reads or changes the flow rules should find them in the language of the rest of the repo, with types, and without a second toolchain. The rules must count exactly what they count today.

## Existing behavior

- `run.sh` calls `perl flows/rules.pl <run dir> <command>` after each run, `perl flows/report.pl` at the end, and `perl flows/compare.pl` for `--compare`.
- `rules.pl` reads `turn-*-assistant.txt` and the matching files, and prints `rule`, `held` or `broken`, and a detail, tab separated. `report.pl` reads `rules.tsv` and `meta.json` and prints a Markdown report. `compare.pl` reads two reports.
- The step `flow-setup.steps.ts` runs `rules.pl` on a folder built by a scenario.
- 35 of the 39 lines in `tests/mutations/flows.tsv` are Perl substitutions on the text of the three files. The runner `tests/mutate.sh` and the break engine in `specs/steps/mutate.steps.ts` run `perl -0pi`. That stays.
- Node 24 and `tsx` are already installed by `npm ci`.

## Agreed examples

- **E1** On each of the 15 recorded runs, the TypeScript rules print the same lines as the Perl rules, for both `discover` and `deliver`. Checked once, before the Perl files are deleted.
- **E2** `report.ts` prints the same report as `report.pl` on the same run folders, and `compare.ts` the same table as `compare.pl` on two reports.
- **E3** All 35 breaks in `flows.tsv` that name a flow script are rewritten for the TypeScript files. `tests/mutate.sh` on `flows.tsv` shows each one caught, or marks it equivalent with a reason, as now.
- **E4** `run.sh` started in a project where `npm ci` has not run stops at its first line with "run `npm ci` first". No run is started and no quota is spent.
- **E5** The flow scenarios in `specs/features/flow-*.feature` pass with the step calling the TypeScript rules.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Which scripts move? | The three flow scripts only (option A). The mutation engine stays in Perl. | The maintainer chose it. The engine needs a byte-for-byte check of 83 breaks. That is option B and its own change. |
| 2 | What happens to the 35 flow breaks? | All 35 are rewritten against the TypeScript files and re-run with `tests/mutate.sh`. | The maintainer chose it. The breaks are the proof that the rules are noticed. Dropping them right after closing the gap would reopen it. |
| 3 | How do we show the new rules match the old? | A one-time comparison of old and new output on the 15 recorded runs, with the result written in the pull request. The Perl files are deleted in the same pull request. | The maintainer chose it. Real transcripts hold edge cases that the scenario fixtures lack. No transcripts are kept as fixtures: they hold real product-manager and model text, and scrubbing 120 messages risks a leaked name. |
| 4 | What when `npm ci` has not run? | `run.sh` checks for `node_modules/.bin/tsx` first, before the comparison and before any run, and stops with one line. | The maintainer chose it. It fails before a paid run starts. It does not change the contributor's folder as a side effect. |
| 5 | Port or tidy? | A faithful port. Same rules, same regexes, same output text, same file names for results. No new rule, no rule changed. | The builder chose it. The comparison in decision 3 only means something if behavior is held fixed. A tidy-up is its own change. |
| 6 | Where do the files live, and how are they called? | `flows/rules.ts`, `flows/report.ts`, `flows/compare.ts`, run with `node_modules/.bin/tsx`. The step calls the same command line as `run.sh`. `tsconfig.json` adds `flows/*.ts` to `include`, so the typecheck covers them. | The builder chose it. Same place and same interface as today. The step keeps testing the real command, not an import. |

## Existing users

- The flow scripts are at the repo root, not in the plugin. No installed project has them. Nothing changes for a project that adopted the plugin.
- A contributor who ran flows before needs `npm ci`, which the Contributing section already asks for. Perl is still needed for `tests/mutate.sh`.
- Old run folders and reports in `flows/results/` are outputs. Their format does not change, so `--compare` still reads them.

## First run

A fresh checkout without `npm ci` that starts `flows/run.sh` sees one line: "run `npm ci` first". After `npm ci` the run is as before.

## Exclusions

- `tests/mutate.sh`, the break engine in the steps, and the 4 non-flow break lines stay in Perl (option B, later).
- `plugin/scripts/decisions.sh` and the install script: shell, not Perl, unchanged.
- No new or changed rule. The look-first phrase list, the plain-words regexes and the pack-end check stay as they are.
- No change to the report text, the `meta.json` shape or the harness options.
- The 15 recorded runs are not added to the repo.

## Result of the comparison (decision 3)

Done before the Perl files were deleted, on the 15 recorded run folders of the repo's earlier flow runs.

- Rules: 30 outputs (15 runs, each as `discover` and as `deliver`). Identical, byte for byte.
- Report: 18 reports (9 run groups, each as both commands). Identical.
- Compare: 81 pairs of the 9 saved reports. Identical.
- What the 15 runs exercise: both `held` and `broken` for `one-question`, `plain-words`, `pack-end`, `report-shape`, `never-reported-passed`, `project-untouched`, and `parked-not-passed` (one break). `look-first`, `approval-asked-once` and `no-feature-before-go-ahead` were held in every run, so only the scenarios and the rewritten breaks guard them.

## Result of the breaks (decision 2)

`tests/mutate.sh` on the rewritten `tests/mutations/flows.tsv`: 36 breaks of the flow code (34 on `rules.ts`, 2 on `run.sh`). 33 caught, 3 survived as expected (the same three marked equivalent before), 0 to look at. The break file now uses `~` as the Perl delimiter, because the TypeScript regexes hold many slashes.

What the move also changed in the tests: two new scenarios check the "run npm ci first" stop (a run and a comparison), and the steps that copy the harness share one helper that links the installed tools into the copy.

## Risks

- Perl and JavaScript regexes differ: `\z`, the `/s` and `/m` flags, `$-[0]`, and the way `split` and `grep` count lines. The comparison on 120 real messages is the check. A difference found there is fixed in the port, or recorded here as a decision.
- 15 runs cover discover and four deliver fixtures. A rare shape in a future run is not covered. The scenarios and the rewritten breaks are the guard after that.

## Not proven by this change

That a rule is right. This change proves only that the rules count what they counted before.

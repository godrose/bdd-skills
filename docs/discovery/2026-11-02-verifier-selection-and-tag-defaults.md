# Discovery: verifier selection by name or file, and tag defaults in implement

## Story

Two gaps showed in a trial on a .NET project whose scenarios carry no per-scenario tags.

1. The `implement` to verifier handoff has `Scope`, `Project` and `Tag`. The verifier's input lists only a tag or a project. The caller had no slot to select by scenario name or feature file, although `run.md` supports tag, name, file and all.
2. Phase 3 of `implement` removes the unautomated tag and adds the automated tag after a pass. It is silent when the config lacks those rows, when the scenario carries no such tag, and when the project does not use these tags.

## Existing behavior (from the plugin)

- `commands/implement.md` dispatches the verifier with `Scope`, `Project` and `Tag`.
- `agents/verifier.md` reports `**Tag:**` and applies a tag or project filter only.
- `commands/run.md` Step 6 lists four selectors: by tag, by scenario name, single feature file, all.
- `commands/discover.md` has a "Defaults when config rows are absent" section. `implement` has none.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How does the handoff express a selection? | Two fields replace `Tag:`: `By: tag \| name \| file \| all` and `Select: <value>`. | A separate value field avoids parsing `kind=value` in free text. Names can hold `=`, quotes and spaces. |
| 2 | Is `Tag:` kept as an alias? | No. A request with `Tag:` stops with "unknown field Tag, use By and Select". | Distribution is low today, so a clean break costs little. A clear error beats a silent wide run. A reversal of the earlier lean toward an additive `Filter:` line. |
| 3 | A name matches more than one test | Run them all. List the matched test names and note "name matched N tests". Not a failure. | Scenario Outlines make multiple matches normal. The runner decides what matches. |
| 4 | Tag changes after a pass | Use the six default rules below. | Removes guessing when rows or tags are absent. |

## Tag defaults (all confirmed)

1. `unautomated_tag` row absent, empty or in `<...>` form: use `@pending`.
2. `automated_tag` row absent, empty or in `<...>` form: add nothing.
3. The scenario does not carry the unautomated tag: change no tags and say "no tag changes: scenario carries no unautomated tag".
4. The scenario is not from an approved spec: do not touch its tags.
5. Add the automated tag only when the unautomated tag was removed.
6. The final report has one line saying which tags changed, or that none did.

Spec id tags are never touched.

## Candidate exclusions (all confirmed)

1. No combining of selectors, no several names in one dispatch, and no exact-match logic. The runner defines matching.
2. No `Tag:` alias.
3. No migration of custom verifiers or project-installed copies. Projects re-run the installer or update their own agents.
4. No change to spec id tags or to how unautomated and manual-only scenarios are excluded.

## Spec points

- **Existing users:** a custom verifier or a project-installed copy written against `Tag:` will not understand `By` and `Select`. Distribution is low today. Projects re-run the installer. Project files and configs are untouched.
- **First run:** a fresh project sees the new handoff and the default tag rules with no config changes.
- **Exclusions:** see above. The change does not fit runners whose name filter cannot select a single scenario. The verifier reports what matched.
- **Files that change:** `agents/verifier.md`, `commands/implement.md` and the tests. No config row and no version bump, since the plugin tracks commits.

## Readiness

Ready. No open questions.

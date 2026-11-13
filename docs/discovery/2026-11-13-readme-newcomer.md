# Discovery: the README for a reader new to BDD and to the plugin

Input: a goldfish test on 2026-11-13. A fresh `claude -p` session in an empty folder held only a copy of `README.md` and the Read tool. Its goal was "add cancel-order to my existing web app using BDD". It could not run anything. Its verdict was "probably not". Four findings were taken, one question each. Also read: `plugin/bdd-config.template.md`, `plugin/commands/implement.md`, `plugin/commands/deliver.md`, and the project diffs of the recorded deliver runs in `flows/results/`.

## Story

A developer who has never heard of BDD, and has no Gherkin runner yet, opens the README. They should know what BDD is, what to install first, which config rows they must fill in, and who writes the feature code, without reading anything else.

## Existing behavior

- BDD, Gherkin, scenario and step definition are never defined. The only example of a scenario is in a GIF.
- Nothing says what to do with a project that has no Gherkin runner.
- The config template has about 25 rows. The README does not say which ones a first run needs. `prepare`, `features_dir` and `steps_dir` appear only in passing.
- The README does not say who writes the feature code, or that a red scenario is expected before green.

## Agreed examples

| # | Finding | What the README says after the change |
|---|---------|---------------------------------------|
| E1 | No runner | A "Before you start" section before Quick start. The plugin does not install a runner. It lists one runner per stack with a link, and says to run init after. |
| E2 | Jargon and no example | A "New to BDD?" section after Contents. It defines BDD, scenario, Gherkin and step definition in plain words and shows one Given/When/Then example (cancel an order). |
| E3 | Config rows | A "Minimum to start" part in Configure. It names the rows a first run needs, one plain line each, and a filled example for a small Playwright-BDD project. Everything else stays optional. |
| E4 | Whose code | A "What you get" part in The flow. `/bdd:implement` writes step code and support code. `/bdd:deliver` also builds the feature. A scenario for an unbuilt feature fails first, on an assertion, and that red is the proof. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Say plainly that the plugin does not install a runner, and name one per stack. No worked setup for one stack. | It is true today, it is cheap, and a walk-through ages with the tool. Chosen by the builder. |
| 2 | A visible "New to BDD?" section above Quick start, not a collapsed block and not an outside link. | A newcomer reads it before any command, an expert skips it, and the plugin's own words stay explained in the plugin's own README. Chosen by the builder. |
| 3 | A "Minimum to start" list in the README with an example. The template is not changed. | A list needs no plugin change, so existing users keep what they have. Every row it names must be a row of the template, and a test checks that. Chosen by the builder. |
| 4 | The README says `deliver` builds the feature, and `implement` writes step code. The plugin text is fixed in a follow-up. | Recorded runs show `deliver` adding code to the app (`src/pages/loans.js` in fixture `c`, story 2), after red scenarios. The command text only hints at it ("fix the step code or the implementation"). The builder confirmed it is the point of `deliver`. |
| 5 | The new checks test structure: sections exist and come in order, the example has Given, When and Then, and each row named in the minimum is a row of the template. No phrase checks on the prose. | The approach review of 2026-11-12 cut prose phrase checks. Contracts between files stay. |

## Existing users

Only the README text changes. No plugin file, no template and no installed project file changes. Nobody has to do anything.

## First run

A reader with no runner sees New to BDD, then Before you start, then Quick start. A reader who knows BDD can skip the first.

## Exclusions

- No new command and no config row.
- No change to `plugin/` (the follow-up change to `deliver.md` and `implement.md` is separate, with its own discovery).
- No worked setup of a runner, and no install help for any runner.
- Findings 5 to 8 of the goldfish report (access, names, dead-end pointers, jargon list) are not in this change.

## Not proven by this change

- That a newcomer succeeds. The goldfish test is run again on the new README to see whether the four findings are gone. One run is one sample.
- That `deliver` always builds the feature. The runs show it did. The follow-up makes the plugin text say so.

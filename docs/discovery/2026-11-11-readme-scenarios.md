# Discovery: the README checks as scenarios

Input: `tests/test_readme.sh` (the source of every example), the scenario-suite pack (`2026-11-11-scenario-suite.md`), and a dialogue with the builder. The behavior already exists. Values are marked "from code".

## Story

The README promises a structure: the way in first, reference material folded, links that resolve, a hero block, and the licence and contributing notes. Migrate the checks of `tests/test_readme.sh` to scenarios. A migration adds no checks.

## Overlap with existing scenarios

None. `repo.feature` checks the README's release wording and changelog link, which the bash file does not. `layout-listing.feature` checks `plugin/README.md` and the plugin licence copy, not the root README or the root copyright line.

## Agreed examples (all from code)

Order (`readme-order.feature`)
- **E1** Sections exist: Contents, Quick start, The flow, Modes, Install, Configure, Decision log, Update.
- **E2** Contents, Quick start, The flow, in that order.
- **E3** The marketplace install line, `/bdd:init` and `/bdd:discover <story>` each come before The flow.
- **E4** The flow, Install, What's included, Update, in that order.
- **E5** Update, Related projects, Contributing, License, in that order.

Folded (`readme-folded.feature`)
- **E6** At least 5 `<details>` blocks, opening and closing tags equal in number.
- **E7** Summaries for Files, Architecture and Optional config rows.

Contents links (`readme-contents.feature`)
- **E8** Every `#anchor` link points at a level 2 or 3 heading.
- **E9** Contents lists Contributing, License and Related projects.

Hero (`readme-hero.feature`)
- **E10** Centered div, pre banner, tagline, three badges.
- **E11** Three tips.
- **E12** The demo GIF exists, is shown, and sits before Contents with the centered block.
- **E13** Related projects names Playwright-BDD, Cucumber and Reqnroll with links.
- **E14** No non-ASCII in `##` headings. No em-dash in the README.

Reference (`readme-reference.feature`)
- **E15** The `prepare` row is listed with the optional rows.
- **E16** The .NET typecheck example forces a recompile.
- **E17** The generate hint (`missingSteps`, `fail-on-run`) and the decision_log question.

Contributing and licence (`readme-contributing.feature`)
- **E18** Contributing and License sections with the contributor details.
- **E19** The last README line is the copyright line.
- **E20** `LICENSE` has the filled-in copyright line and no template placeholders.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How are the scenarios grouped? | Six files, by what a maintainer would notice: order, folding, links, hero, reference, contributing. | Smaller files, as asked. Order checks that were spread through the old file are gathered. |

## Existing users

Nothing changes in a user's project. The README and the version stay as they are.

## First run

A contributor runs `npm ci`, then `bash tests/run.sh`. The new files run beside the bash file until it is deleted in the same pull request.

## Exclusions

- Any new README check. Reason: a migration adds none.
- The bash helpers.

## Kept as they are

- E3 and E4 find the first line that contains the text, anywhere in the file.
- E8 reads only `#anchor` links and only level 2 and 3 headings.
- E1 does not require "What's included" to exist, but E4 does.

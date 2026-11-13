# Discovery: deliver and implement build the feature, and a company skill can do it

Input: the follow-up of `2026-11-13-readme-newcomer.md` (decision 4), the recorded deliver runs in `flows/results/` (fixture `c`, story 2: the agent added `overdueNotice` to `src/pages/loans.js` after red scenarios), `plugin/commands/implement.md`, `plugin/commands/deliver.md` and `plugin/bdd-config.template.md`. Three questions were asked, one at a time.

## Story

A developer or product manager runs `/bdd:deliver` (or `/bdd:implement`) for a feature that does not exist yet. The scenarios fail first on an assertion. The plugin then builds the feature until they pass. A company that has its own way of writing application code (standards, layers, a TDD skill) can point the plugin at it.

## Existing behavior

- `implement.md` says it handles "execution only": step definitions, page objects, helpers and support code. It never says it builds the feature.
- `deliver.md` says "fix the step code or the implementation and re-run" in one sentence, and "Do not write step code yourself".
- In the recorded runs the agent did build the feature. The text did not tell it to, and the README (#94) said so for `deliver` only.
- Skill roles in the config template are the plugin's hook points. `domain-knowledge` and `requirements-sync` are optional roles a company points at its own skills.

## Agreed examples

| # | Situation | What happens |
|---|-----------|--------------|
| E1 | A scenario fails on an assertion because the feature is missing, and no `feature-builder` row is set | The agent makes the smallest change in the application that turns it green, and lists the files it changed in the report. |
| E2 | The same, with a `feature-builder` skill in Skill Roles | The agent invokes that skill to write the application code. The skill's standards apply. |
| E3 | The `feature-builder` row names a skill that cannot be found | One line says so, and the agent uses the default as in E1. |
| E4 | The feature-builder skill stops to ask something about behavior | It is an open decision, asked as one plain question to the product owner, as `implement` already does. A technical stop is parked after 3 tries. |
| E5 | The step code is wrong (undefined step, locator not found, timeout) | That is a step problem, fixed in step code as before. Application code is changed only when the step code is right and the assertion fails because the application does not do it. |
| E6 | The scenario itself looks wrong | A product decision, asked, as before. An approved scenario or its expected values never change to make a check pass. |
| E7 | `workflow_mode` is `specify-only` | No implement step, so nothing is built. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Both `deliver` and `implement` build the feature. This reverses "execution only" in `implement.md`, and the README line of #94 that said `implement` alone does not. | Chosen by the builder. A developer who uses discover, design and implement should get the same result as `deliver`. |
| 2 | A new optional role `feature-builder` in the Skill Roles table. Row absent: the default of E1. Row set: invoke that skill. | Roles are the plugin's own hook points. One row lets a company use its coding standards without a new mechanism. Name chosen by the builder. |
| 3 | No extra approval before application code is edited. The two approvals of `deliver` stay. | Chosen by the builder. The runs did this, and a third gate slows the flow that `deliver` is for. |
| 4 | Same limits as the fix loop: 3 tries, an approved scenario and its expected values never change, and the report lists the application files changed. In `deliver` they go on the "For the developer" line. | The plain-words part of the report must not name files (existing rule). |
| 5 | A stop from the company skill follows E4. | `deliver` asks only the product owner, one question at a time. |
| 6 | A `feature-builder` row that cannot be resolved is said in one line, then the default applies. My call. | The same shape as the other optional roles. A hard stop would block a run for a name typo. |
| 7 | `/bdd:init --detect` does not propose this role in this change. My call. | The proposal needs its own matching rule and tests. It is a follow-up. |
| 8 | The checks are contracts between files and one reversed decision, not phrases of prose: the template has the row, `implement.md` and `deliver.md` name the role and give the default, `implement.md` no longer says "execution only", and the README no longer says `implement` does not build the feature. | The approach review of 2026-11-12. |

## Existing users

- The template gains an optional row. A project that already has a config keeps it. An absent row means the default. `/bdd:init` never overwrites a config.
- What changes for them: `implement` and `deliver` now change application code when a scenario fails on an assertion and the step code is right. Before, the text did not say so, and the runs did it anyway. The release notes say it plainly.
- A project's own skill that happens to be named `feature-builder` is not used unless the row names it.

## First run

A fresh project has the row in its template as `<your-feature-builder-skill>`, marked optional. A value in `<...>` form counts as empty, so the default applies.

## Exclusions

- `init --detect` does not propose the role.
- No hook into a company's CI, branches, reviews or approval workflow. They live outside the conversation.
- No new approval gate.
- Mobile, desktop or other platforms are not treated differently. The role is a skill name, and the skill knows the platform.

## Result of a real run (default path, no feature-builder row)

One `deliver` run on fixture `c`, story 1 (an overdue notice with days late), with this branch's plugin text. 115 seconds, 4 turns, all nine harness rules held, no breaks. The agent built the feature: `src/pages/loans.js` (the notice) and `src/jobs/markOverdue.js` (the shared 14-day limit) changed, with three new steps. E1 and E2 were seen red naturally, because the page had no notice. The application files were listed in the developer note, and the plain sentences named no file. This is the default path of E1. The company-skill path (E2) was not run.

## Result of a real run with a stand-in skill (E2)

The same story on fixture `c`, with a Skill Roles table naming `acme-feature-builder`, a stand-in project skill with four house rules (code under `src/`, a `// ACME:` comment line on every new function, `const` arrow functions, no logging, and a closing line). The fixture was changed in the working tree for the run only and put back. 153 seconds, 7 turns, all nine harness rules held, no breaks. Before the first edit the agent said in the developer note that application code would be written with the `acme-feature-builder` rules. The new function `overdueNotice` in `src/pages/loans.js` has the `// ACME:` line and is a `const` arrow function, and nothing logs. The other change in application code was one export added to `src/jobs/markOverdue.js`, which is no new function. The agent did not print the exact closing line of the skill. The final report is in plain words by design, so it carries no such line. So the role is found and followed. Not shown: how the agent called the skill, and a skill that asks a question of its own (E4).

## Not proven by this change

- That a company's own skill works well inside `deliver`. The role is tested for its text. A stand-in skill was followed in one run (above). A real company skill, and one that asks its own questions (E4), were not tried.

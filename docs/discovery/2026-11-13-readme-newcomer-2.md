# Discovery: the README for a newcomer, second part (access, names, pointers, jargon, small gaps)

Input: the goldfish report of 2026-11-13 (findings 5 to 8) and the second goldfish run on the README after `2026-11-13-readme-newcomer.md` (the smaller gaps), `README.md`, `plugin/agents/verifier.md`, `plugin/commands/implement.md`, `plugin/bdd-config.template.md`, `.claude-plugin/marketplace.json`. The repo is private today. The builder said it will go public and that the names (`godrose/bdd-skills`, `gennadyverdel-plugins`, `bdd`) are final. One question was asked: how the README treats access while the repo is private.

## Story

A developer who has only the README should know how to get access, what the three names mean, where every pointer leads, what each plugin word means, and what to do when their stack or checks differ from the examples.

## Existing behavior

- The README says the repo is "private for now" and gives no way to ask for access. A person without access cannot open an issue, so an issue is no route.
- `gennadyverdel-plugins` appears in the install lines and is never explained.
- `CLAUDE.md`, `flows/README.md` and `CHANGELOG.md` are named in backticks, not linked.
- ACs, discovery pack, reuse audit, verifier, red-first, headless, triage, reconcile, drift and orphan are not explained.
- The runner table has overlapping rows for a TypeScript web app, no line for stacks that are not listed, and no concrete check that a runner works.
- The README does not say whether `typecheck` may be empty. The verifier text says only "Run the typecheck command", and the recorded runs on fixture `c`, which has an empty row, skipped it by the agent's own choice.

## Agreed examples

| # | Finding | What changes |
|---|---------|--------------|
| E1 | Access | The Access paragraph says how to ask: message the owner on GitHub, with a link to the profile. It says the repo is planned to go public. |
| E2 | Three names | A short list in Quick start: repository, marketplace, plugin, and what `bdd@gennadyverdel-plugins` means. |
| E3 | Dead-end pointers | The three files are linked with relative links. A test checks that every relative link in the README points at a file that exists. |
| E4 | Jargon | A Glossary section before Related projects, linked from Contents and from New to BDD?. One line a term. |
| E5 | Runner check and unlisted stacks | Before you start gets a one-scenario check for a new runner and a line naming Behave, Behat and godog for stacks that are not in the table. The two JavaScript rows say when to pick which. |
| E6 | Empty typecheck | The verifier skips step 5, and says so in one line, when the typecheck row is absent, empty or in `<...>` form. The same in the manual path of `implement`. The template placeholder says "empty to skip". The README says to leave it empty if there is none. |

## Decisions

| # | Decision | Reason |
|---|----------|--------|
| 1 | Say how to ask for access now. A separate small PR at go-public removes the private text, the clone-only route and the scenario that checks it. Chosen by the builder. | The README stays true today, and nothing in it claims what is not yet so. |
| 2 | The route to ask is the owner's GitHub profile, not an issue and not an email. My call. | A person without access cannot see the repo, so an issue is out of reach. No personal address goes in the README. |
| 3 | The names list says the marketplace is the catalog the repo publishes. My call, with the names confirmed final by the builder. | One sentence is enough and does not change with the names. |
| 4 | Links are relative, so they work in the repo view. A check covers every relative link. My call. | A dead link is a contract between the README and the files. |
| 5 | The Glossary is a section, not an inline explanation at each first use. My call. | The words come up in many places. One page of one-line terms is cheap to keep right. Each term is defined from the command text (`reconcile.md` for orphan and drift). |
| 6 | The empty typecheck row is a plugin text change, not only a README line. My call. | The README line would rest on what the agent happened to do. The template, verifier and implement text now say it. It matches how `prepare` already works. |
| 7 | The checks are contracts between files, as in the first part: the install line names the marketplace of `marketplace.json`, every relative link exists, the glossary and the sections sit where they should, and the verifier and template carry the empty-typecheck rule. No prose phrase checks beyond one for the rule. | The approach review of 2026-11-12. |

## Existing users

- The template placeholder of the `typecheck` row changes for new installs only. A config that exists keeps what it has.
- A project with an empty typecheck row now gets one line saying the type check was skipped. Before, the verifier text did not say what to do.

## First run

Same as the first part. The reader sees the access line, the names, a glossary, and a runner check.

## Exclusions

- The go-public change (private text, curl route, the scenario that checks it).
- No new command and no config row.
- No change to what `typecheck` does when it is set.
- `init --detect` is untouched.

## Not proven by this change

- That a newcomer succeeds. The goldfish test is run again. One run is one sample.

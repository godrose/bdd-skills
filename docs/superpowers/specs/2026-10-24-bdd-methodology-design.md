# godrose/bdd: from scenario tooling to a BDD methodology

Status: DRAFT for review. Items marked **[decided]** come from the author. Items marked **[my call]** are the designer's guesses and need confirming.

## Intent

The lasting benefit of BDD is the discussion between the product manager (PM) and the builders. Concrete examples discussed before building remove surprises. The discussion only pays off when it ends in automation. Otherwise the examples go stale and the loop breaks. **[decided]**

Today `godrose/bdd` encodes the automation half well: design from acceptance criteria (ACs), implement steps, verify. It starts at "ACs exist". The discussion that produces the ACs and scenarios is not covered. This work adds it and evolves the same repo. **[decided]**

**Primary audience for v1: the individual builder.** The builder owns the story and builds it with an agent, so the PM role collapses into the builder and the agent takes the questioning side. What they get: they see in plain words what they will get before it is built, the agreed behavior becomes automated checks that guard against later agent changes, and the shared steps and vocabulary make each feature cheaper than the last. Team features (a separate PM, the spec-only PR) stay available and opt-in. **[decided]**

## The flow (team, opt-in)

1. The PM writes a user story in the tracker (Jira). **[decided]**
2. The PM and the builder discuss it. **[decided]**
3. The builder formulates scenarios with the agent and skills. **[decided]**
4. The builder opens a spec-only pull request. No automation yet. **[decided]**
5. The PM reviews only the formulations. Their comments are mostly wording and missing cases. **[decided]**
6. After approval, automation is implemented using the existing implement and verify skills.
7. Results are pushed back to the ticket (AssertThat binds scenarios to the Jira ticket). **[decided]**

Two modes. The default stays **specify and implement** in one run (today's behavior). **Specify-only** (stop at the spec PR, automate later) is an opt-in option. **[decided]**

## The flow (builder, default) [my call on the details]

1. The builder describes what they want, or points at a tracker item.
2. `bdd-discover` runs as a dialogue in the session. It asks one question at a time and proposes examples, edge cases and exclusions. Trivial changes skip it (size gate).
3. `bdd-design` presents the scenarios in plain words with the step reuse audit. The builder approves in chat.
4. `bdd-implement` automates them and `bdd-verifier` checks them.
5. A saved discovery pack, a PR summary and a tracker sync are optional extras.

## Goals

- Add a discovery stage before `bdd-design` that turns a story into questions, candidate examples, edge cases and negative paths for the discussion. **[my call: name `bdd-discover`]**
- Make the spec-only PR a first-class artifact the PM can review without knowing the step library. **[my call]**
- Keep step reuse a hard rule across all stages. Reuse is the default. A new step needs a stated reason. **[decided]**
- Keep the config-driven role model and framework independence (Playwright-BDD, SpecFlow, Cucumber). **[decided]**
- Keep the tracker binding optional. AssertThat and Jira are one implementation of the requirements-sync role. **[my call]**
- Let the skills themselves improve from use: a lesson about the method is promoted into the generic skills by PR, as PRs #7 to #12 did. Product-specific lessons stay in the project's own knowledge skill. There is no automated lessons route. **[decided]**

## Non-goals

- Support for agents other than Claude Code. Later. **[decided]**
- Replacing or competing with superpowers TDD. This sits above it as an outside-in layer. **[my call]**
- A runner, framework or CLI. This stays a set of skills and one install script. **[my call]**

## Anti-goals (what would make this a failure even if it works) [my call]

- Gherkin ceremony with no conversation behind it.
- A spec PR the PM cannot read without engineer context.
- Automation that starts before the scenarios are agreed.
- Step-library drift: paraphrased duplicates, vocabulary forks.
- Observed failures worked around instead of reported. The existing principle "if something fails, it's a finding, not a bug to work around" stays.

## Components

Existing, kept (see `.claude/`): `bdd-design`, `bdd-implement`, `bdd-run`, `bdd-verifier` agent, `bdd-config.template.md`, `install.sh`.

New or changed [my call throughout]:

| Component | Purpose |
|---|---|
| `bdd-discover` | Input is a story (tracker key, URL or pasted text). Output is a discussion pack: open questions, proposed examples, edge and negative cases, term check against the glossary. Ends when the builder and PM agree scenarios are ready to formulate. |
| `bdd-design` (changed) | Starts from the discussion pack or ACs. Stops at the spec-only PR. No longer goes straight into implementation. |
| Spec PR summary | Plain-language mapping from story to scenarios. Lists cases included and cases deliberately excluded. Lists new terms. Shows each step as existing (automated) or new (to be built), as a cost signal. |
| Vocabulary sweep | Mines existing `.feature` files and step definitions for the project's terms and casing, as a manual grammar analysis of one project did. Flags scenarios that drift. An optional glossary file covers terms that live outside the code (for example in Confluence). Machine-checkable conventions (tag format, casing, indentation) belong in a project linter, and the skills point to it. **[my call, from the findings of an earlier project analysis]** |
| Discussion transport | The discussion pack is a plain document, usable as a PR description, tracker comment or shared page. The PM meets it at the PR today. A live remote session with the PM is a desired later direction and is not designed for in v1. **[decided: direction; my call: v1 scope]** |

## Constraints

- Claude Code skills only (commands, agents, config). **[decided]**
- Existing users must be able to update by re-running `install.sh` without losing `bdd-config.md`. **[my call: preserve current behavior]**
- No em-dashes in any generated text. Short, simple sentences. **[author's style rule]**

## Left to the builder

- Exact file format of the discussion pack and the PR summary.
- Whether the glossary is one file or per feature area.
- How `bdd-design` detects "spec-only" state (for example a tag or a branch convention).
- Wording and structure of the skills themselves.

## Open questions for the author

1. Did Confluence hold any vocabulary or conventions worth ingesting? Not inspected by the designer.

# Discovery: rename the repo `godrose/bdd` to `godrose/bdd-skills`

> Superseded in part by `2026-11-05-first-pinned-release.md` (decision 9): the marketplace name is now `gennadyverdel-plugins`. The rest stands.

## Story

Rename the GitHub repo to `bdd-skills`. The plugin name stays `bdd`, so `/bdd:*` commands and users' configs do not change. The name `bdd` is generic for a repo and does not say what it holds. `bdd-skills` matches the README title, is neutral about the agent, and sits beside the .NET project. `bdd-ai` was considered and rejected: it is vague, dates fast and promises that the AI does the whole job.

## What the old name touches (from the repo)

- `install.sh`: `REPO_URL`, the raw `curl` URL in the header comment, the clone comment, and the `# Source:` header it writes.
- `.claude-plugin/plugin.json`: `homepage` and `repository`.
- `README.md`: CI and stars badges, `/plugin marketplace add godrose/bdd`, the `curl` install line and the clone line. The clone already goes to `/tmp/bdd-skills`.
- `commands/init.md`: the leftover rule greps for `# Source: https://github.com/godrose/bdd`.
- Tests that assert those strings: `test_install.sh`, `test_plugin.sh`, `test_skills.sh`, `test_readme.sh`.
- Old specs and discovery packs under `docs/`. They are history.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Rename the repo only, or the plugin too? | Repo only. The plugin stays `bdd`. | `/bdd:discover` is short and users already type it. A plugin rename changes every command and config. |
| 2 | Name | `bdd-skills`, not `bdd-ai` and not `bdd`. | Matches the README title. Says what the repo holds. Neutral about the agent, so Codex fits later. |
| 3 | Do `init` and the leftover rule match both the old and the new `# Source:` URL? | No. Only the new URL. | There are almost no existing installs. A leftover from an old install would go unreported. Accepted. |
| 4 | Order | PR with the new strings merges first. Then the repo is renamed. | The code never points at a name that does not exist yet. GitHub redirects old to new only. |
| 5 | Local folder and remote | After the rename, `git remote set-url origin` to the new URL. Keep the folder `bdd`. | Claude Code keys project memory and history by folder path. A folder rename orphans them. |
| 6 | Hero | Banner stays `bdd`. A one-line note under the install commands says the repo is `bdd-skills` and the plugin is `bdd`. | The banner is the plugin name users type. The note answers why `install bdd@...` does not say `bdd-skills`. |
| 7 | Guard against the old name | One test fails if any file outside `docs/` contains `godrose/bdd` not followed by `-skills`. It is dropped later. | A stray old string is easy to paste back. The test must fail before the change. |

## Existing users

Almost none. Files written by the old installer keep `# Source: https://github.com/godrose/bdd` and `init` no longer reports them (decision 3). Users who added the marketplace as `godrose/bdd` keep working through the GitHub redirect.

## First run

A new visitor lands on `godrose/bdd-skills`, sees the hero, then runs `/plugin marketplace add godrose/bdd-skills` and `/plugin install bdd@godrose-plugins`. A note explains the two names.

## Candidate exclusions (all confirmed)

1. The plugin name `bdd` and the `/bdd:*` commands. Reason: no user-facing change.
2. The marketplace name `godrose-plugins`. Reason: it is the account catalog.
3. Old specs and discovery packs under `docs/`. Reason: history.
4. The sibling .NET repo and the demo project. Reason: separate projects.
5. Never create a new repo at the old name `godrose/bdd`. Reason: it breaks the GitHub redirect.
6. The Codex adapter. Reason: separate discovery.

## Open risk

Between the merge and the rename, the README names a repo that does not exist yet. The gap is minutes if the rename follows the merge.

## Readiness

Ready for `bdd:design`. No open questions. Every exclusion is confirmed.

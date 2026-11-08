# Working on this repo

This repo is a BDD methodology. Use it on itself.

## Substantial changes start with discovery

Run discovery before writing a spec or any code when the change is any of these:

- a new command, agent or config row
- anything in install, packaging or distribution
- anything that changes what existing users already have in their projects

Skip it only for what `commands/discover.md` calls trivial: a one-line fix, a rename, a copy edit. Say so in one sentence.

Discovery means the questions, examples, edge cases and exclusions that `/bdd:discover` asks, one question at a time. Run it with `claude --plugin-dir <this repo>`, or follow `commands/discover.md` by hand. Save the pack in `docs/discovery/`.

## The spec must cover

- **Existing users:** what already exists in a project that adopted the earlier version, including their own files with similar names. What happens to them.
- **First run:** what a user sees in a fresh project with no config.
- **Exclusions:** what the change does not do, and the frameworks and platforms it does not fit.
- **Decisions:** each one with its reason. A reversal says what it replaces.

Spikes and trials on real projects still come after discovery. They find what questions cannot, such as cache behavior and real project layouts.

## Rules

- Plugin text uses plugin names (`bdd:design`). `install.sh` converts it for project installs. Do not write project-form names or `.claude/scripts` paths in the plugin tree.
- Run `bash tests/run.sh` before every commit. A new test must fail before the change.
- Never tell users to delete with a `bdd-*` glob. Their own skills match it.

## Releasing

The plugin version is pinned in `plugin.json` and the marketplace entry. Only release PRs change it. Feature PRs never bump it. The first pinned version is `0.4.0`. It stays below `1.0.0` until the plugin is called stable.

A release PR:

1. Has a title that starts with `release:`. CI then runs `tests/check_release.sh`, which fails unless the version is higher than on `main`.
2. Sets the same `version` in both manifests.
3. Adds a `## <version>` entry to `CHANGELOG.md`. Every PR checks that the entry exists.
4. Ticks the release box in the PR template.

After the merge, tag and publish by hand, using the changelog entry as the notes:

```bash
git checkout main && git pull
git tag v<version> && git push origin v<version>
gh release create v<version> --title v<version> --notes-file <file holding the entry>
```

A fresh install gets `main` as it is, not the tag. A release is what the tag and the changelog name.

Details: `docs/discovery/2026-11-05-first-pinned-release.md`. The earlier choice to let users track commits is in `docs/discovery/2026-11-02-track-commits.md`.

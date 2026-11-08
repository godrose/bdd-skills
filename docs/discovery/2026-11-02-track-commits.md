# Discovery: stop bumping the plugin version on every change

> Superseded by `2026-11-05-first-pinned-release.md` (decision 8). Kept as the record of the earlier choice. The "To resolve before going public" list below is done.

## Story

Every change to `commands/`, `agents/`, `scripts/`, `schemas/` or the config template needed a plugin version bump, because the plugin cache is keyed by version. Eight PRs produced 0.1.0 to 0.1.7 in about two days. Each bump touches three files and can conflict between parallel PRs. The repo is private and pre-release, and the number carries no meaning yet.

## What Claude Code does (from its docs)

- The version is resolved in this order: `version` in `plugin.json`, then `version` in the marketplace entry, then a value from the source type.
- For a relative-path plugin inside a Git-hosted marketplace, that value is the commit SHA of the installed directory.
- The docs say: to let users track commits, leave `version` out of both the manifest and the entry.
- `--plugin-dir` and a marketplace added from a local path load the current files at every session start, whatever the version says.
- `claude plugin validate` warns about a missing `version`. It fails only with `--strict`. This repo's CI does not run it.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | How do users get changes? | Remove `version` from `plugin.json` and `marketplace.json`. Every merge to `main` is a new version. | No manual bumps, no conflicts. The repo is private and pre-release, so there is no stability promise to protect. |
| 2 | What replaces the bump rule? | A "Before going public" note in `CLAUDE.md`. | The choice is temporary. The note says what to do at the first stable release. |
| 3 | What guards against a stray `version`? | A test fails if either manifest sets `version`. | A pin would freeze users on a cached copy without any sign of it. |

Alternatives rejected: bump only in release PRs (needs a release step nobody does yet) and automate the bump (more tooling for a number nobody reads).

## To resolve before going public

At the first stable release:
1. Pin a version in `plugin.json` and the marketplace entry.
2. Bump it only in release PRs, not in feature PRs.
3. Restore the bump check for releases (`assert_version_bumped` stays in `tests/lib.sh` for this), and replace the "no version" test.
4. Restore the PR template checkbox for releases.
5. Update the README update section: users get changes at releases, not at every merge.

## Edge cases (all confirmed)

1. Existing installs pinned at 0.1.x move to the SHA version on the next update. Checked with a trial (see the PR).
2. Relative-path source in a Git-hosted marketplace gives the SHA version. Checked with the same trial.
3. Local-path marketplaces and `--plugin-dir` are unchanged.
4. A stray `version` added later fails the new test, with a message that points at the note.

## Candidate exclusions (all confirmed)

1. No release tooling, tags or changelog now.
2. No change to `install.sh` or project installs. They copy files and do not use the plugin cache.
3. No stable-release claim.
4. No automation of bumps.

## Spec points

- **Existing users:** their next `plugin update` installs the SHA version. Their project files are untouched.
- **First run:** a new install gets the current `main` as a SHA-named cache folder.
- **Exclusions:** see above. This does not fit a plugin that promises stability to outside users, which is why the note exists.
- **Files that change:** both manifests, `CLAUDE.md`, the PR template, `README.md`, `tests/test_plugin.sh`, `tests/test_repo.sh`.

## Trial result

Run with an isolated config dir and a scratch Git-hosted marketplace (a local repo behind a rewritten https URL):

1. Installed the plugin pinned at 0.1.6. The cache folder was `0.1.6`.
2. Published the manifests without `version`, then ran `marketplace update` and `plugin update`. Result: updated from 0.1.6 to `d9dc731c4d84`, a 12-character commit SHA, in a new cache folder.
3. Published a content-only commit to `commands/run.md`, with no version change. `plugin update` moved from `d9dc731c4d84` to `8b466294d4a4`, and the cache held the new text.

A marketplace added from a plain local path does not exercise this, because it loads in place.

## Readiness

Ready. Edge cases 1 and 2 are checked.

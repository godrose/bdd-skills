# Discovery: the first pinned release (0.4.0)

Input: the "Before going public" list in `CLAUDE.md`, the earlier pack `2026-11-02-track-commits.md`, the Medium publish checklist of the demo project, and a look at how comparable plugin repos release.

## Story

The plugin has no `version`, so every merge to `main` is a new version for users. That was right while the repo was private and pre-release. Before the repo goes public, users need a version they can name, a list of what changed in it, and a way to know when something new is ready. The first pinned release is an early pre-1.0 release, not a stable one. More changes are expected before the plugin is called stable.

## What comparable repos do (from their public repos, checked 2026-11-05)

| Repo | Pinned version | Tags and releases | Notes file |
|---|---|---|---|
| `anthropics/claude-plugins-official`, `anthropics/skills`, `wshobson/agents` | no | none | none |
| `anthropics/claude-code` | yes | yes | `CHANGELOG.md` |
| `obra/superpowers` | yes | yes | `RELEASE-NOTES.md`, same text as the release body, plus a list of files that hold a version |

The repos that pin a version tag, publish releases and keep a notes file in the repo. The repos with no tags track commits, as this repo does today.

## Existing behavior

- No `version` in `plugin.json` or `marketplace.json`. Claude Code uses the commit SHA, so `plugin update` installs the newest `main`.
- `assert_version_bumped` is in `tests/lib.sh` and not called. It fails when plugin files changed but the version did not.
- Tests assert that neither manifest sets `version` (`tests/test_plugin.sh`) and that the PR template has no bump checkbox (`tests/test_repo.sh`).
- `claude plugin validate .` warns about the missing version and about a missing marketplace description. `--strict` fails. CI does not run it.
- No tag, release, `CHANGELOG.md`, `CONTRIBUTING.md` or `SECURITY.md`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | First version | `0.4.0`. | Still pre-1.0, because the builder expects more changes before it is called stable. It is higher than the old `0.1.0` to `0.1.7`, so version order holds. `1.0.0` is for the stable release, after the nightly evals and early users show it is ready. Chosen over `0.9.0` (a release candidate), which the builder replaced. |
| 2 | What is a release | A version bump in both manifests, a `CHANGELOG.md` entry, a tag `vX.Y.Z` and a GitHub release made from that entry. | The repos that pin a version do all four. The entry is reviewed in the release PR. |
| 3 | Who creates the tag and release | By hand with `gh`. The release PR description carries the two commands. | No new workflow and no `contents: write` permission. A release every few weeks does not need automation. |
| 4 | Order with going public | Release first, install it on a clean machine from the tagged version, then make the repo public and fix the article's link. | Problems in the install are found before the public sees them. |
| 5 | Who bumps | Only release PRs. Feature PRs never change the version. | `CLAUDE.md` step 2. Avoids the eight bumps in two days that the earlier pack removed. |
| 6 | The bump check | Every PR: both manifests carry the same semver, and `CHANGELOG.md` has a heading for that version. Release PRs only (title starts with `release:`): a CI step runs `assert_version_bumped`, so the version must be higher than on `main`. | Feature PRs cannot be forced to bump, and a release PR cannot forget to. |
| 7 | Keeping two files in sync | A test, not a script. | There are two files. A bump script is worth it from about five. |
| 8 | A reversal | This replaces decision 1 of `2026-11-02-track-commits.md` ("remove `version`, every merge is a new version") and its exclusions "no tags or changelog" and "no stable-release claim". It still makes no stable claim: `0.4.0` is an early release. | The earlier pack said the choice was temporary and listed this work. |

## Existing users

- **Installed from the marketplace (SHA version):** the next `plugin update` moves them to `0.4.0`. The trial must confirm it.
- **After that:** a merge to `main` does not reach them until the next version bump. The README update section says so. This is the main change in behavior.
- **A fresh install after unreleased merges:** `plugin marketplace add` installs the default branch as it is at that moment, labelled with the version in `plugin.json` on `main`. Users on `0.4.0` do not get those merges, a new installer does. The README says so and the trial must confirm it.
- **Project-form installs (`install.sh`):** unchanged. They copy files and do not use the plugin cache. Their `bdd-config.md` is never overwritten.
- **`--plugin-dir` and a local-path marketplace:** unchanged. They load the current files at every start.
- **A user's own files:** nothing is written into their projects. A user's own `CHANGELOG.md` or tag is not touched, because the release files live only in this repo.

## First run

A fresh install of the tagged state gets plugin `bdd` at `0.4.0`. `/plugin install bdd@godrose-plugins` works as in the README. A project with no config sees the same `init` flow as today.

## Edge cases

All confirmed by the builder.

1. A feature PR that changes `version` is not blocked by a test, only by review and the PR template. The test cannot tell a feature PR from a release PR.
2. A release PR whose version does not rise fails the `release:` CI step.
3. The two manifests disagree: every PR fails the consistency test.
4. `CHANGELOG.md` has no heading for the current version: every PR fails.
5. A tag is pushed before the release PR merges: the release would point at the wrong commit. The commands in the PR description run after the merge.
6. The version in the manifests is not valid semver: the consistency test fails.

## Exclusions

All confirmed by the builder.

1. No release workflow and no tag automation (decision 3).
2. No version-sync script (decision 7).
3. No stable (`1.0.0`) claim.
4. No change to `install.sh` or the project-form install.
5. Making the repo public, the Medium article and its link are not part of this PR (decision 4).
6. No submission to a plugin directory, and no `--strict` validation in CI in this PR. The directory's safety and policy review is a separate step.
7. No `CONTRIBUTING.md` or `SECURITY.md`. They can come before going public, separately.

## Files that change

Both manifests (version, marketplace description), `CHANGELOG.md` (new), `README.md` (update section), `CLAUDE.md` (the "Before going public" section becomes a short "Releasing" section), `.github/pull_request_template.md`, `.github/workflows/ci.yml`, `tests/test_plugin.sh`, `tests/test_repo.sh`.

## Tests to write first

Each must fail before the change.

- Both manifests set `version` and it is the same semver.
- The marketplace has a description.
- `CHANGELOG.md` has a heading for the current version.
- The PR template has a release checkbox (replaces the "no bump" assertion).
- `ci.yml` runs the bump check only for titles that start with `release:`.
- The README update section no longer says each merge is a new version, and names the changelog.
- `CLAUDE.md` no longer says the version is unpinned.

## Trial

Run on 2026-11-05 with Claude Code 2.1.318, an isolated config dir and git config, and a scratch Git-hosted marketplace (a local bare repo behind a rewritten URL), as in the earlier pack:

1. Install the SHA-versioned plugin, then publish `0.4.0` and run `plugin update`. Expect `0.4.0`.
2. Publish a content-only commit with no bump and run `plugin update`. Expect no change for the installed user.
3. Install fresh at that point. Expect the new content labelled `0.4.0`.
4. Bump to `0.4.1` and run `plugin update`. Expect the new content.

Result: all four held.

1. The SHA install (`69c33daa108c`) updated to `0.4.0`.
2. A content-only commit with no bump: `bdd is already at the latest version (0.4.0)`. The installed copy did not have the new text.
3. A fresh install at that point: version `0.4.0`, and it did contain the new text. Two users on `0.4.0` can therefore have different content until the next bump. This is the cost of pinning. The README must say that a fresh install gets `main` as it is, and a release is only what the tag and the changelog name.
4. The bump to `0.4.1`: `plugin update` installed it, with the new text.

## Readiness

Ready for `bdd:design`. No open questions. Every edge case and exclusion is confirmed.

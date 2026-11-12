# Handoff: the scenario suite is done, what is next

For the next session. The migration of the repo's own tests from bash to scenarios is finished. This note says where things stand, what is open, and how the work was done, so it can go on without the old conversation.

## Where things stand

- Every bash test file is gone. The suite is scenarios only: `specs/features/` (feature files), `specs/steps/` (TypeScript steps) and `specs/fixtures/`.
- `tests/` holds `run.sh` (runs the scenarios), `ci_local.sh` (the CI steps, named when one fails) and `check_release.sh` (release PRs only, self-contained).
- Run `npm ci` once. Then `bash tests/run.sh` before every commit and `bash tests/ci_local.sh` before every push. Type check: `npm run typecheck`. One tag: `NODE_OPTIONS="--import tsx" npx cucumber-js --tags @decisions`.
- 537 scenarios, all passing. The full run takes about a minute.
- Work goes through pull requests against the base branch `base/scenario-suite`. The series #56 to #71 is merged or open there. Merging that base branch into `main` is a separate pull request and the maintainer's call. `main` still has the old bash-only CI until then.
- Nothing is released. `0.7.0` waits on known gap G11 and the `0.6.0` directory review. Do not release without the maintainer.

## What happened, in order

1. Install, layout, decisions, readme, flow harnesses, evals, red-first and known-gaps checks were migrated one file at a time. Each ran `/bdd:deliver` headless, then a mutation check (break the real code many ways, compare the old bash file with the new scenarios), then deleted the bash file.
2. The text checks (`deliver.md`, plugin manifests and text, `test_skills.sh` in three parts) were migrated the same way.
3. An approach review (`2026-11-12-approach-review.md`) asked whether phrase checks on prompt text test an outcome. Rule: keep a text check only if it is a contract between files, a reversed decision (`does not contain`) or policy. 35 files were dropped and 14 trimmed. The red-first files stay because known gap G5 names them.
4. The cleanup moved the folders to `specs/` and removed `tests/lib.sh`, `tests/test_lib.sh` and the bash loop (see the outcome section of `2026-11-11-scenario-suite.md`).
5. The mutation survivors were triaged (`2026-11-12-mutation-survivors.md`). The decisions script group is fixed in PR 71.

## Open

Ordered by what I would do first.

1. **Merge PR 71** if it is not merged yet (decisions survivors and a `show` fix for `resolves` given as a list).
2. **Install survivors (2):** removing a legacy file and the "skipped" line are not caught. Real behavior of `install.sh`. Small.
3. **Flow harness survivors (15 for deliver, 8 for discover):** rule counting edge cases such as the developer line, out-of-scope, approvals, ranges, failed status, a page file, paths, the Delivered line, counts written another way. Each needs a look at `flows/` code first. A fake `claude` drives them.
4. **Eval survivors (8):** five are README or CI guide phrase pins, which the approach review decided not to keep. Check the other three (`fake-lint` ticket rule, lint draft file pattern, `run.sh` tool call).
5. **Evals as a guard on prompt edits.** The approach review left the evals and the flow harness as the guard for prompt wording. They run by hand or nightly (gated by the repo variable `EVALS_NIGHTLY`), not on every push. Known gaps G7 and G12 are open for this. Decide whether a small subset should run on a schedule.
6. **A cross-check** that every flag and code named in `reconcile.md` is accepted by `decisions.sh`. Today it is a phrase check.
7. **Merge `base/scenario-suite` into `main`.** The maintainer's call. It also brings in the new CI.
8. **Other ideas, not decided:** a `deliver` mode that checks two runs for equivalence, message assertions for the release check, a "where is this case" view for adaptive case management.

## How the work was done

- **Discovery first.** The repo `CLAUDE.md` requires it for a new command, an install change or anything that changes what users have. Skip it only for a one-line fix, a rename or a copy edit, and say so. Packs live in `docs/discovery/` with a row in `docs/README.md`. A pack covers existing users, first run, exclusions and decisions with reasons. A reversal says what it replaces.
- **Use the method on itself.** Each migration ran `/bdd:deliver` headless: `claude -p "/bdd:deliver <story>" --plugin-dir plugin --session-id <new uuid> --output-format json --allowedTools ...`, then `--resume <id>` for each answer. The first approval is the checklist and the second is the scenarios as text. Nothing is written before both.
- **Launch lessons.** Run `claude` itself as the background command, not a subshell. Use a new session id each run and `< /dev/null`. The agent cannot run commands outside its grants, so run the tag run and `bash tests/ci_local.sh` yourself.
- **Mutation check.** Break the real code or files in many ways (a literal replace, first occurrence or global), reset with `git checkout -- .` after a work-in-progress commit, and compare old against new. A scenario must fail on the break. Equivalent mutants (no input can tell them apart) are left and noted.
- **Shell notes.** macOS, no `timeout` (use `perl -e 'alarm N; exec @ARGV'`). The working copy has CRLF through autocrlf, so scripted edits need `\r?`. zsh does not split `$VAR` into words: use `${=VAR}`. A glob with no match aborts a chain.

## Rules that bit

- No em-dash anywhere (prose, comments, commits). Use a spaced hyphen.
- Plugin text uses plugin names (`bdd:design`). `install.sh` converts it. No project-form names or `.claude/scripts` paths in `plugin/`.
- The plugin folder holds only Markdown, text, JSON, YAML and PNG, JPEG, GIF, WebP or ICO. No file starting with `#!`, no package-manager config, no `allowed-tools` beyond Read, Grep, Glob and LS.
- Never tell users to delete with a `bdd-*` glob. Their own skills match it.
- A feature pull request never bumps the version. Only a release pull request does, with `release:` in the title, the same version in both manifests and a `## <version>` entry in `CHANGELOG.md`.
- Commit messages end with the Co-Authored-By line only. No session links in commits or pull request bodies.
- Force-push is denied by the auto classifier. Push a follow-up commit, or a new branch.
- Keep project names and local paths out of anything committed.
- Never change an expected value to make a test pass. A regression test must fail before the fix.
- Look at the real result before saying a UI change works.

## How the maintainer likes to work

- Short, plain status first: what was added, where, which pull requests.
- One decision at a time, with a recommendation. Approvals come as "yes", "approved" or "merged N".
- Smaller feature files for readability. Do not write a scenario that an existing one covers.
- The maintainer merges each pull request. Report counts accurately, and list survivors and open items in the pull request.
- Watch the plan budget on long runs. A plugin run costs about 0.3 to 1.1 dollars notional, and the login expires about 2026-11-18.

## Known gaps still open

G7 (no flow eval of `deliver`), G8 (out-of-scope items not linked to a tracker), G9 (noisy `deliver-first-gate` eval), G10 (only new scenarios checked against titles), G11 (no live run with a person new to the method), G12 (`deliver` assumes a developer). See `docs/known-gaps.md`.

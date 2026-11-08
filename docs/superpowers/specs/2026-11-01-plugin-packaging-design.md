# Plugin packaging - design

> Superseded in part by `2026-11-05-first-pinned-release.md` (decision 9): the marketplace name is now `gennadyverdel-plugins`. The rest stands.

Date: 2026-11-01. Status: scoped, spike done, not yet approved for implementation.

## Intent

Ship the BDD skills as a Claude Code plugin named `bdd`. Users then get `/bdd:design`, `/bdd:discover` and so on, installed with `/plugin marketplace add godrose/bdd`. `install.sh` stays for people who want plain project files.

## Why

- Today `install.sh` copies files into `.claude/`. Updates mean re-running a script.
- The `bdd-` prefix in every file name is a hand-made namespace. A plugin gets a real one for free.
- The plugin system handles install, update and removal.

## Goals, non-goals

Goals:

- One plugin, `bdd`, with all six commands and the verifier agent.
- Same behavior as today. Only names and paths change.
- A clear migration note for current users.

Non-goals:

- No new features, skills or config rows.
- No stable-release claim. The first version is `0.1.0`.
- No change to the per-project `.claude/bdd-config.md`. It stays in the user's project.

## Naming

The plugin system prefixes every command with `<plugin>:`. So the files lose their `bdd-` prefix, or users get `/bdd:bdd-design`.

| Today | Plugin file | Invoked as |
|-------|-------------|------------|
| `bdd-discover.md` | `commands/discover.md` | `/bdd:discover` |
| `bdd-design.md` | `commands/design.md` | `/bdd:design` |
| `bdd-implement.md` | `commands/implement.md` | `/bdd:implement` |
| `bdd-run.md` | `commands/run.md` | `/bdd:run` |
| `bdd-feedback.md` (now `bdd-triage.md`) | `commands/triage.md` | `/bdd:triage` |
| `bdd-reconcile.md` | `commands/reconcile.md` | `/bdd:reconcile` |
| `bdd-verifier.md` | `agents/verifier.md` | `bdd:verifier` |

Plugin layout, at the repo root:

```
.claude-plugin/plugin.json
.claude-plugin/marketplace.json
commands/*.md
agents/verifier.md
scripts/decisions.sh
schemas/decision.schema.json
bdd-config.template.md
```

The marketplace entry name `bdd` is an immutable slug. Pick it once.

## Spike results (2026-11-01)

A throwaway plugin was loaded with `claude -p --plugin-dir`, using the real `decisions.sh` and schema.

| Question | Result |
|----------|--------|
| Does `/bdd:<name>` work? | Yes. `commands/probe.md` ran as `/bdd:probe`. |
| Is `${CLAUDE_PLUGIN_ROOT}` substituted in a command body? | Yes. A command that only echoed the text got the real absolute path, with no tool call. |
| Does the script run from the plugin root? | Yes. `check` ran and printed its findings. |
| Does the script keep its executable bit? | Yes (`-rwxr-xr-x`). |
| Does `decisions.sh` find its schema? | Yes, with no change. It reads `$SELF_DIR/../schemas/decision.schema.json`, so `scripts/` and `schemas/` as siblings is enough. |
| Is the prefix stutter real? | Yes. `commands/bdd-stutter.md` showed as `bdd:bdd-stutter`. |
| How does the agent appear? | `bdd:verifier`. |

## Marketplace check results (phase 1, 2026-11-01)

Done with the `claude plugin` CLI against two scratch marketplaces. Nothing was published. The first marketplace pointed at a local folder. The second pointed at a git URL (`file://`), which is the closest local match to a GitHub install. Both were removed afterwards.

| Question | Result |
|----------|--------|
| `marketplace add`, `install`, `update`, `uninstall` | All work. Install at project scope is recorded for that project only. |
| Run the installed plugin with no `--plugin-dir` | Yes. `/bdd:probe` ran. |
| Folder marketplace: where does the plugin run from? | From the source folder, not a cache copy. `${CLAUDE_PLUGIN_ROOT}` pointed at the folder. |
| Git marketplace: where does it run from? | From a cache copy, `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`. |
| Executable bit after a git install | Kept (755). |
| Update from 0.1.0 to 0.1.1 | `marketplace update` then `plugin update` worked. The new version got its own cache folder. |
| Same version, new content | Not picked up. After uninstall and reinstall at the same version, the cache folder was empty and the plugin was broken. Only a version bump fixes it. This confirms the version-bump rule below. |
| Does a self-hosted marketplace get an `installCount`? | No. The field did not appear for either scratch marketplace. It is shown only for plugins in Anthropic's catalog. |

Line endings are a real risk. With `core.autocrlf=true` (set on this machine, and the default for Git on Windows), the plugin clone checked out `decisions.sh` with CRLF. Running it failed with `bad interpreter: /bin/bash^M`. A `.gitattributes` line `*.sh text eol=lf` in the plugin repo fixed it: the clone had LF and the script ran. The repo already has that line. The plugin work must keep it and add a test that the line exists.

Other consequences:

- The cache is keyed by version, so every release needs a bump. A test should fail when a command, script or schema changed and the version did not.
- Because the folder marketplace runs from the source, a local test during development is live. A git install is not.

## Coupling to change

- Skill names: 89 mentions of `bdd-<skill>` across 9 files (skills, README, installer, tests).
- Script and schema paths: `.claude/scripts/decisions.sh` and `.claude/schemas/` appear in `bdd-design`, `bdd-feedback` and `bdd-reconcile`, in `install.sh`, and in `tests/test_install.sh` and `tests/test_decisions.sh`. In the plugin they become `${CLAUDE_PLUGIN_ROOT}/scripts/decisions.sh`.
- Role table in `bdd-config.template.md`: the skill column holds the namespaced names. Roles resolve by name, so a project config written for the old names must be updated.
- README install and update sections.

## Project-file install (no plugin)

Some users will not install a plugin. They run `install.sh` and keep the files in their repo.

What they get:

- `.claude/commands/bdd-*.md`, `.claude/agents/bdd-verifier.md`, `.claude/scripts/decisions.sh` and `.claude/schemas/`. Commands are `/bdd-design`, `/bdd-feedback` and so on. The names do not change from today.
- No namespace. The `bdd-` prefix is the namespace.
- Updates by re-running the script. `bdd-config.md` is never overwritten, and the installer prints a note for each new config row.
- The files are committed, so the whole team runs the same version.
- No dependency on the plugin system, so older Claude Code versions and locked-down setups still work.

What the plugin work must keep true:

- The plugin files lose the `bdd-` prefix, so a plain copy would give `/design` and `/run`. `install.sh` must restore the prefix when it copies.
- The scripts live at `${CLAUDE_PLUGIN_ROOT}/scripts/` in the plugin and at `.claude/scripts/` in a project install. Two ways to cover both:
  - **Rewrite on install:** `install.sh` replaces the plugin paths and skill names in the copied text.
  - **Lookup rule:** each skill says "use `${CLAUDE_PLUGIN_ROOT}` when it is set, else `.claude/scripts/`". There is one text and no rewriting, but the rule is repeated in every skill that calls the script.
- The role table in `bdd-config.md` holds `bdd-design` for project installs and `bdd:design` for the plugin. The template and the installer notes must cover both.
- The tests run against both outputs.

Recommendation: one source tree, a generated project copy, and path rewriting on install. Try the lookup rule in phase 4 and keep it only if it is simpler.

## Measuring usage

Why measure: it decides how long `install.sh` stays. Use real numbers, not a guess.

What exists today (checked 2026-11-01):

- **Catalog install count.** `claude plugin list --available --json` returns an `installCount` for each plugin in the marketplaces it knows. For example, `agent-sdk-dev` shows 67988. This is a catalog figure that Anthropic maintains. A self-hosted marketplace does not get one (phase 1 check), so this number is out of reach until the plugin is in Anthropic's catalog.
- **GitHub traffic.** `gh api repos/godrose/bdd/traffic/clones` gives clones and unique cloners for the last 14 days, and `traffic/views` and `traffic/popular/referrers` give page views. Only people with push access can read them, and the data is kept for 14 days, so it must be saved on a schedule. It counts interest, not installs.
- **Stars, forks, issues.** Public and permanent, but weak. Directory sites that cannot see installs rank plugins by stars.
- **Plugin author analytics.** A feature request for install counts, active users and version spread was filed in April 2026 and closed in May 2026. I could not confirm that anything shipped. The docs name no author dashboard.

What established plugins do: as far as I could verify, nothing more than the above. The official marketplace shows `installCount`. Authors outside it use stars and clones. I found no plugin in the local marketplace that reports its own usage.

What we should not do: add telemetry to the skills or `decisions.sh`. It would be invisible to users and cut against a tool that runs on their code and Slack text.

Proposed measures, in order of cost:

1. Record `installCount` if the plugin is ever listed in Anthropic's catalog. Until then it is not available.
2. A weekly job, run by the maintainer, that saves the GitHub clone and referrer numbers to a file outside the repo.
3. Compare `install.sh` use against plugin use by pointing the README's two install lines at different tagged releases or URLs, so that GitHub referrers and release download counts show the split.
4. Ask users. A short note in the migration text ("tell us if you still need the project-file install") costs nothing.

Decision rule for dropping `install.sh`: no complaint in two releases and the plugin count is the majority of known installs. Otherwise keep it.

## /bdd:init --detect

`/bdd:init` copies the template. `/bdd:init --detect` also proposes values for the rows that are still placeholders and writes the ones the user approves. It is opt-in, plugin-only, and follows the propose-and-confirm pattern of `bdd-feedback`.

Rules (all in `commands/init.md`):

- It never changes a row that already has a value, so running it again only touches rows that are still placeholders.
- It reads files only: build and package files, framework config, CI workflow files, README and `CLAUDE.md`, `.feature` files and step definitions. It does not run the project's commands.
- Each proposal has a value, the file it came from, and a confidence. `unknown` is written when the files do not answer. `unknown` rows are never written.
- Paths are full paths from the project root, never abbreviations.
- A row that does not apply is proposed as `_(not needed: <reason>)_`. `run` and the verifier skip a `generate` row that is empty, still a placeholder, or a `_(...)_` note.
- A repo with several test projects makes it ask which one to configure. A repo with no BDD makes it propose nothing.
- Commands for another platform, and things that stop a command working locally, are noted.
- Nothing is written until the user answers.

Evidence (pilot, 2026-11-01). The same read-only prompt ran on eight projects: Playwright-BDD (1), SpecFlow (4), Go with godog (2) and one project with no BDD.

- No path in any answer was made up. Every "not found" was an abbreviation of a real path or a file created at run time.
- Answers said `unknown` where the repo had no answer, and labeled their own guesses. The project with no BDD got `unknown` on all ten rows.
- The Playwright project scored 9 of 10 rows exact or equivalent against its real config. The SpecFlow project in the workspace scored 6 of 10. The three command rows were off there, because the right command depends on the platform and on choices not stored in the repo, such as the Mac solution file and `-warnaserror`.
- CI workflow files were the best source for commands in the Go projects.
- One real config was wrong: its `config_file` named a file that does not exist. A human has to judge proposals; string matching against an old config would have been wrong.

Not covered: none of the proposed commands was run, each project ran once, and the real `--detect` command (as opposed to the pilot prompt) has been checked by dry run only.

## Plan

1. **Marketplace check. Done (see results above).** Install, update and removal work, and the executable bit survives a git install.
2. **Restructure.** Move files to the layout above. Drop the `bdd-` prefix. Add `plugin.json` (version `0.1.0`) and `marketplace.json`. Done.
3. **Rewrite references. Done.** Skill names, script paths and the role table were converted in phase 2. Phase 3 added a one-line "Plugin note" to the three skills that call the script (design, feedback, reconcile): if the script path still starts with `$` or the script is missing, say the plugin root was not set, and stop. The note does not contain the variable itself, because the plugin system would expand it and hide the failure. `install.sh` removes the note from project installs. The failure case itself cannot be triggered from a normal session, so only its text and its removal are tested.
4. **Dual install. Done.** `install.sh` generates the project copy from the plugin tree. Checked three ways: its output is byte-identical to the pre-restructure install, the tests cover both outputs, and a piped install (`curl | bash` shape) works against the new layout. The piped route clones `main`, so it works once this branch is merged.
5. **Tests and docs. Done.** The tests point at the new layout. `assert_version_bumped` (in `tests/lib.sh`) fails when a command, agent, script, schema or the config template changed since the merge-base but the plugin version did not. The README has a plugin install, a config copy step, a project-file install with its hyphen names, and update steps for both.
6. **Migration note. Done.** The README section "Moving from project files to the plugin" says to delete the old files, keep the config and rename the roles to `bdd:<name>`. It also asks users to say if they still need the project-file install.

## Decisions

Made:

- Plugin name `bdd`. Version `0.1.0`. The skills have not had a stable release, so no stability claim is made.
- `bdd-config.md` stays in the user's project.
- Marketplace name `godrose-plugins`, so the install id is `bdd@godrose-plugins`. Chosen over `godrose-bdd`, `methodology-plugins` and `claude-code-methodology`: it follows the `<owner>-plugins` pattern, is unlikely to clash, and does not limit the catalog to one product. Names starting with `claude-code-` are avoided because they resemble Anthropic's reserved names.
- `install.sh` generates the project copy from the plugin tree (resolves open question 2). Phase 2 did this and the result is byte-identical to the earlier install.
- `/bdd:init` is in 0.1.0 and only copies the template: it never overwrites, and it does not fill in or detect anything. It is plugin-only, so `install.sh` does not install it. Detection was left out of the first cut and added later as the opt-in `/bdd:init --detect` (see that section). Other setup routes were considered and not taken: `userConfig` is stored per user, not per project, so it cannot hold per-project test commands; a `SessionStart` hook would write files into every project where the plugin is enabled, without being asked, and would still leave the placeholders unfilled. The skills that need the config (design, implement, run, feedback, reconcile and the verifier) say so and stop when `.claude/bdd-config.md` is missing. In the plugin, a Plugin note gives the template path. `discover` is left out because it has defaults for missing rows.

Open:

1. Does `install.sh` stay, and for how long? Recommendation: one or two releases.
2. (Settled in phase 2, see above.)
3. (Settled in phase 5: bump the version in every release PR. The version-bump test enforces it.)
- Command names are imperative verbs in flow order (`discover`, `design`, `implement`, `run`, `triage`, `reconcile`, `init`), and agents are role nouns (`verifier`), as in the official plugins. `feedback` was renamed to `triage` because it was the only noun and shares a name with Claude Code's built-in `/feedback`. The role name `feedback-intake` stays.

## Risks

- `jq` and `shasum` stay the user's responsibility. A plugin does not install them.
- A user with both old and new files sees two sets of commands.
- Phase 1 covered the CLI only. The interactive `/plugin` menu was not driven, and a real GitHub install was not tried because nothing is published.

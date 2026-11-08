# Discovery: meet the directory's file and tool policy

Input: the directory's refusal of `v0.5.0` on 2026-11-08 ("Directory policy refused this version"), and a read of every file in `plugin/`.

## Story

The directory accepts a submission from an organization that is not Verified only when the plugin folder holds no script, no program and no file outside a short list of types, and when no `allowed-tools` list goes beyond `Read`, `Grep`, `Glob` and `LS`. `v0.5.0` breaks both rules, so an automatic check refused it. The plugin should pass the check, and existing users should keep what they have.

## What the check refuses

| Rule | What is in `plugin/` today |
|------|----------------------------|
| `allowed-tools` beyond Read, Grep, Glob and LS (any entry, even a narrow `Bash(...)`) | All seven commands: `Agent`, `Bash`, `Write`, `Edit`, `AskUserQuestion` |
| Files that start with `#!` | `scripts/decisions.sh`, six `scaffold.sh`, `fake-lint.sh`, `fake-test.sh` |
| Files outside Markdown, text, JSON, YAML and PNG, JPEG, GIF, WebP and ICO | `scripts/decisions.sh`, the shell scripts above, 7 `.ts` and 4 `.feature` fixture files, 3 `.gitkeep` |
| Package-manager configuration | `evals/init-audit/fixture/package.json` |

The icon, `LICENSE` and the README pass.

## Existing behavior (from the commands)

- `triage` and `reconcile` call `decisions.sh` through `${CLAUDE_PLUGIN_ROOT}`. `install.sh` rewrites the path to `.claude/scripts/decisions.sh` and removes the "Plugin note" lines.
- `reconcile` is built on the log. It says the log is off and stops when `decision_log` is not `on`.
- `triage` already classifies and proposes `.feature` edits when the log is off.
- Both say "the plugin root was not set" and stop when the script is not found. That is the wrong message once the plugin does not ship the script.
- The eval tool reads cases only from a folder below the plugin (`--eval-dir` is "below the plugin").
- `install.sh` copies the commands, the script and the schema from `plugin/`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | `allowed-tools` in the plugin | Removed from all seven commands. The plugin pre-approves nothing. | The policy allows only Read, Grep, Glob and LS, and refuses even narrow `Bash(...)` entries. A rename or a trick that passes the check would defeat its purpose. |
| 2 | The decision log script | `decisions.sh` and the schema move to `scripts/` and `schemas/` at the repo root. The plugin does not ship them. `install.sh` still installs them. | A script cannot be in the plugin. The log is optional. |
| 3 | `design`, `triage` and `reconcile` without the script | A missing script is said plainly. `design` and `triage` go on without records, as it does when the log is off, and says nothing was recorded. `reconcile` stops and says why. `init --detect` does not offer to turn the log on. | Never record silently. `reconcile` has no useful half mode. The builder chose this. |
| 4 | Project-file installs | `install.sh` writes each command's former `allowed-tools` line back into the installed copy. A test holds the table. | Project installs are not scanned, and existing users keep their behavior. The builder chose this. |
| 5 | The evals | `plugin/evals/` moves to `evals/` at the root. `evals/run.sh` and the CI workflow build a temporary copy of the plugin with the cases inside it, and run the eval tool there. | The tool needs cases below the plugin, and the plugin cannot hold them. |
| 6 | Version | The next release is `0.6.0`. No bump in this change. | Users see new prompts and lose the script in the marketplace form. That is not a patch. |
| 7 | Earlier decisions | `2026-11-08-allowed-tools-decision.md` and known gap G6 are replaced. The pack gets a "Superseded" note, and G6 is removed. | The grants are gone. A reversal says what it replaces. |
| 8 | `CLAUDE.md` rule | The rule "no `.claude/scripts` paths in the plugin tree" stays, and a rule is added: the plugin tree holds only the allowed file types, no `#!` and no `allowed-tools` beyond the four read tools. A test enforces it. | It keeps the plugin passing without a manual check. |

## Existing users

- **Marketplace, at `0.5.0` or earlier:** nothing changes until `0.6.0` is released. After the update the commands prompt for shell and file calls, unless the user's settings allow them. With `decision_log` on, `triage` still works and records nothing, `reconcile` stops with a message. The message says what to do.
- **Project-file installs (`install.sh`):** the same grants as today, the same script and schema. A re-run changes nothing in behavior.
- **Their own files:** `install.sh` does not touch user files that are not its own, as before.

## First run

A fresh marketplace install shows no script and no log. `/bdd:init` copies the config. `init --detect` does not offer the log, and says why.

## Exclusions

- No hook, no MCP server, no new script.
- No renamed script. A shebang-less `.txt` copy would pass the check and defeat its purpose.
- No change to what a command does when the log is off.
- No attempt to become a Verified organization here.
- No change to the evals' cases or graders. Only where they live.

## Tests first

Each must fail before the change.

- No file under `plugin/` starts with `#!`, and every file has an allowed extension (or is `LICENSE` or `.gitignore`).
- No `allowed-tools` line under `plugin/` names anything but Read, Grep, Glob or LS.
- `plugin/scripts` and `plugin/evals` do not exist. `scripts/decisions.sh`, `schemas/decision.schema.json` and `evals/` do, at the root.
- `triage` and `reconcile` say what to do when the script is missing, and `init` does not offer the log without it.
- The installed command copies carry the same `allowed-tools` lines `0.5.0` shipped, from a table in the test.
- `evals/run.sh` builds a temporary plugin copy with the cases inside, and the CI workflow uses it.
- The README's "Tool permissions" section no longer says the commands pre-approve tools.

## Trial after the change

Run `claude plugin validate plugin --strict`. Run one eval case through `evals/run.sh`. Run `install.sh` into a fresh folder and compare the commands. Submit and read the directory's decision.

## Readiness

Ready. Decisions 3 and 4 were confirmed by the builder. The rest follow from the policy.

## Trial results (2026-11-08)

- `claude plugin validate plugin --strict` and `claude plugin validate .` pass.
- `bash evals/run.sh` on `init-audit` and `triage-approval-gate`, one run each: both score 1.00. The first attempt could not find `init-audit`, because on macOS `cp -R dir/ dest/` copies the folder's contents. A test with a stub `claude` now covers it.
- A project install in a fresh folder carries each command's former `allowed-tools` line, the script and the schema, and no plugin note.
- `triage-approval-gate` has the log on and now runs the missing-script path. Known gap G6 records that no eval runs the script itself.
- Not tried: the directory's own check on the new version. That comes with the submission.

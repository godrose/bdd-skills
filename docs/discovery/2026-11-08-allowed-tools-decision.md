> **Superseded** by `2026-11-08-directory-policy.md`. The directory refused the plugin for these grants, so they were removed.

# Discovery: the broad `allowed-tools` grants

Input: the directory's validation reports of 2026-11-08, and a read of each command for what its tools are used for.

## Story

The directory scan holds the plugin for a reviewer. Its commands pre-approve bare `Bash` in all seven, bare `Write` in three (`implement`, `run`, `triage`) and bare `Edit` in three (`implement`, `init`, `triage`). The scan asks to narrow them to exact commands and paths. The question is whether to narrow, and how.

## What the commands use the tools for

| Command | Shell use | Narrowable? |
|---------|-----------|-------------|
| `reconcile` | `decisions.sh` at a fixed path, `git merge-base` | Yes |
| `init` | copies the template, a `find .claude` leftover check | Partly |
| `discover` | the configured **lint** command | No |
| `design` | the **lint** command, and the temp draft file | No |
| `triage` | `decisions.sh`, the **lint** command | No |
| `run`, `implement` | the **prepare**, **generate** and **test** commands | No |

`Write` and `Edit` paths come from `bdd-config.md` rows (`features_dir`, `steps_dir`, `decisions_dir`). A grant in front matter cannot read them. The only fixed scope would be `./**`, which is as wide as the bare tool.

## Options considered

1. Keep the grants, accept the hold, and say why in the listing README.
2. Narrow `reconcile` and part of `init`. Clears the finding for those two only, so the hold stays.
3. Remove `allowed-tools` from `discover`, `design` and `triage`. Clears most findings, but adds a permission prompt for the lint command in three commands.
4. Build the grants from the project's config at install time. Not possible in a plugin, where nothing runs at install.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | Narrow the grants? | No. Keep them as they are. | The commands run the user's own configured commands. Narrowing `reconcile` and `init` would not clear the hold, and would add churn and risk for no gain. |
| 2 | Say why? | A "Tool permissions" section in `plugin/README.md`, the listing text. | A reviewer and a user both read it. |
| 3 | Record the gap | `docs/known-gaps.md` entry G6, with what would close it. | Known gaps are listed, not buried. |
| 4 | Submit with the hold? | The builder decides when. The hold only routes the plugin to a reviewer. | |
| 5 | Version | No bump. The next release PR lists it. | Feature PRs never bump. |

A first plan was to narrow where cheap (option 2). Reading the commands showed that only `reconcile` and part of `init` qualify, so this pack replaces it.

## Existing users

No change. No command text or grant is touched.

## First run

A fresh install behaves as today. The listing now explains the grants.

## Exclusions

- No change to any command or any `allowed-tools` line.
- No attempt to clear the hold. A reviewer reads the plugin.
- No hooks. Known gap G3 covers them.

## Tests first

- `plugin/README.md` has a "Tool permissions" section that names `bdd-config.md` and links `known-gaps.md`.
- The known-gaps shape test covers G6.
- The docs index names this pack.

## Readiness

Ready. No open questions.

# Changelog

Releases are tagged `vX.Y.Z`. Before `1.0.0` the plugin can still change in ways that need an edit to your config. The notes say when.

## 0.7.1 (2026-11-13)

`/bdd:implement` and `/bdd:deliver` now say that they build the feature in your app, and a company skill can do that part. Nothing in your `bdd-config.md` needs to change.

### What you will notice

- **Application code changes. Read this first.** When a scenario fails on an assertion because the app does not do what it says, and the step code is right, `/bdd:implement` and `/bdd:deliver` build the feature in your application. They make the smallest change that turns the scenario green, ask for no extra approval, stop after three tries, and list the application files they changed. The text did not say so before, though the runs often did it. Work on a branch and read the diff before you merge.
- **`feature-builder` role (new, optional).** Name your own skill for writing application code in the Skill Roles table, and `implement` and `deliver` use it. Without the row they build it themselves. A skill you name in the request, such as "use our X skill for the code", is used for that run and wins over the row. A skill that cannot be found is said in one line, and the default applies.
- **The `deliver` report names each example once.** An example under "Not checked, and what it risks" says `couldn't be checked`, never also `passed`, even when its scenario passed.
- **An empty `typecheck` row is skipped.** The verifier and `implement` skip the type check and say so in one line when the row is absent, empty or still a placeholder. The template placeholder now says "empty to skip".

### Project-file installs

- Re-run `install.sh` to get the changed commands, the verifier and the template. `bdd-config.md` is never overwritten. No row is required.

### Repo

- The README is rewritten for a reader new to BDD: what BDD is, what to install first, the minimum config, which path to take, and a glossary. It is written for a public repository. The tooling rows for SpecFlow and Reqnroll no longer name one project's build configuration, and the Cucumber (Maven) rows now use options that Maven accepts.
- Perl is gone. The flow scripts and the mutation runner use TypeScript, so `flows/run.sh` and `tests/mutate.sh` need `npm ci`. `TSX_BIN` points them at another `tsx`.
- About 730 scenarios in `specs/features`.

## 0.7.0 (2026-11-12)

A new command, `/bdd:deliver`, and changes to `discover`, `design` and `implement`. Nothing in your `bdd-config.md` needs to change.

### What you will notice

- **`/bdd:deliver` (new).** One conversation from a plain description to verified scenarios, for a product manager with or without a developer watching. It runs discover, design, implement and run for you and asks for two approvals: the checklist of agreed examples, then the scenarios. It looks at the real result before it reports, and ends with a report in plain words. A product decision is asked at once. A technical stop is parked and reported as a plain risk, with a line for the developer. The audit table goes under a "For the developer" line.
- **`/bdd:discover` looks first.** Before the first question it searches the scenarios, steps, screens and code for the story's words, and says in plain words what it found, or that it found nothing and which words it tried. It reads the out-of-scope list and asks where a shown value comes from. It asks one question per message. It offers a Scenario Outline against separate scenarios by those names.
- **`/bdd:design` checks more.** It checks that a scenario asserts what its title claims (the audit table gains a "Claims" column). It checks the setup a scenario depends on: a reused `Given` that passes when its prerequisite is missing is flagged, and a prerequisite that cannot be checked is listed under "Assumed, not checked". This replaces the old advice to add an informational Background step for such prerequisites.
- **`/bdd:implement` scopes locators.** It no longer settles a locator that matches several elements with `.first()`. It also reports an open product decision in a fixed shape (Open decision, Found, Options), so a caller can turn it into one question.
- **Out-of-scope list.** Exclusions and removals go in `docs/out-of-scope.md`, or the file named by the new optional row `out_of_scope_file`. Without the row the default is used, and a missing file means nothing is ruled out.

### Project-file installs

- Re-run `install.sh` to get `bdd-deliver` and the changed commands. A file of your own at `.claude/commands/bdd-deliver.md` that is not an installer copy (no "# Source:" line) is skipped and left as it is. Rename it to keep it, then run `install.sh` again.
- `bdd-config.md` is never overwritten. `install.sh` prints a note for each newer row your file lacks, with its default. No row is required.

### Repo

- The tests are scenarios, about 670 in `specs/features` with steps in `specs/steps`. The bash tests are gone. `tests/mutate.sh` breaks a copy of the code on purpose to show which changes the tests miss. It runs by hand.
- `flows/run.sh` plays a whole `discover` or `deliver` conversation in a real headless session, with a model as the product manager, and counts rules on the transcript. It runs by hand and not in CI.
- Known gaps: G11 (no live run of the design title check and the discover first step) is closed by the maintainer's decision, because the scripted runs count. G7 and G12 stay open.

## 0.6.0 (2026-11-08)

The plugin now passes the directory's policy for organizations that are not Verified. That policy allows no pre-approved tools beyond Read, Grep, Glob and LS, and no scripts or fixtures in the plugin folder. Two things change for marketplace users. Nothing in your `bdd-config.md` needs to change.

### What you will notice

- **Permission prompts.** The seven commands no longer pre-approve `Bash`, `Write` or `Edit`. Claude Code asks before each shell command and file write, unless your own settings allow them. To keep the old behavior, allow those tools in your project settings.
- **The decision log script.** The marketplace plugin no longer ships `decisions.sh`. With `decision_log` set to `on` and no script, `design` and `triage` go on without records and say "Nothing was recorded". `reconcile` stops and says it needs the project install. `init --detect` no longer offers to turn the log on.

### Project-file installs

- No change. `install.sh` copies `decisions.sh` and the schema from the repo root, and writes each command's former `allowed-tools` line back into the installed copy. Re-run it to update. Nothing in your project behaves differently.

### Repo

- `scripts/`, `schemas/` and `evals/` moved to the repo root. They are not part of the plugin.
- Run the evals with `bash evals/run.sh`, which builds a temporary copy of the plugin with the cases inside it. The nightly workflow does the same.
- A test fails if the plugin folder holds a file type the directory refuses, a file that starts with `#!`, package-manager config, or an `allowed-tools` entry beyond Read, Grep, Glob and LS.
- The known gaps list a new entry: no eval runs the decision log script. The earlier entry on broad grants is gone, with its pack marked superseded.

## 0.5.0 (2026-11-08)

The plugin now lives in a `plugin/` folder, so the directory scan and the cache hold only what users install. Nothing in your project or your `bdd-config.md` needs to change.

### Commands

- `/bdd:implement` has a red-first check. After the step code is written, it sees each scenario fail for the stated reason before it counts as passing. It uses a natural red when there is one, and otherwise breaks the step code on purpose and restores it. A scenario it could not see red keeps the unautomated tag, and the report says so on a `Red-first:` line.

### Repo

- The plugin moved into `plugin/`: `commands/`, `agents/`, `scripts/`, `schemas/`, `bdd-config.template.md`, `evals/`, a short `README.md` and a `LICENSE`. The marketplace entry points at `./plugin`.
- To run the plugin from a clone, use `claude --plugin-dir <clone>/plugin`. Pointing it at the clone root no longer works. Use `claude plugin validate plugin` and `claude plugin eval plugin` too.
- `install.sh` reads from `plugin/`. It says "could not clone" when the clone fails, and "no plugin/ folder" when a source has none. In both cases it leaves your project untouched.
- A plugin listing icon, and a "Tool permissions" section in the plugin README that says why the commands pre-approve `Bash`, `Write` and `Edit`.
- `docs/known-gaps.md` lists what the plugin does not check, with why and what would close each gap.
- The CI token setup for the nightly evals moved from `plugin/evals/README.md` to `docs/evals-ci.md`.
- CI runs `claude plugin validate plugin --strict` on a pinned Claude Code version.

## 0.4.0 (2026-11-05)

The first pinned version. Until now the plugin had no version, so every merge to `main` reached users at once. From here, `plugin update` delivers a change when a new version is released. A project that installed the plugin earlier moves to `0.4.0` on its next update.

### Commands

- `/bdd:discover`, `/bdd:design`, `/bdd:implement`, `/bdd:run`, `/bdd:triage`, `/bdd:reconcile` and `/bdd:init`, framework-agnostic and driven by `bdd-config.md`.
- `/bdd:design` lints the draft before showing it, through a temporary `.bdd-draft-*` file, and acts only on findings in the draft. It lists assumptions for vague acceptance criteria and shows scenarios in full.
- `/bdd:implement` works for projects without a UI and groups steps by risk (`step_batch`), so the loop needs fewer test runs.
- `/bdd:run` never reports zero tests run as a pass, and can pick a verifier by name or file.
- `/bdd:init --detect` proposes skill roles, hints for `generate` and the decision log, and audits values that already exist. Its audit ends with one fixed line. It also reports files left over from the older project-file install.

### Config

- Rows: `prepare`, `step_batch`, `decision_log`, `discovery_dir`, `lint`, `glossary_file`, `scenario_id_prefix` and `automated_tag`. Every row is optional.
- `steps_dir` can list several paths, comma-separated, for projects whose step code is split across folders.
- Your existing `bdd-config.md` is never overwritten. The installer prints a note for each newer row your config lacks.

### Decision log

- Optional. `decisions.sh` records approved decisions, and `/bdd:triage` and `/bdd:reconcile` read it.

### Repo

- Evals with `claude plugin eval` for five commands, and a workflow that runs four of them on demand and nightly once the repository variable `EVALS_NIGHTLY` is set.
- Apache-2.0 licence.

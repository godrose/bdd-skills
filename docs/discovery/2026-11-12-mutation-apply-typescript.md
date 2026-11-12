# Discovery: the mutation runner applies a break with TypeScript, not Perl (option B, scope A)

Input: a read of `tests/mutate.sh` (89 lines), the check step in `specs/steps/mutate.steps.ts`, the 84 breaks in `tests/mutations/*.tsv`, `specs/features/mutate-runner.feature`, and the flow-script move that came before (`2026-11-12-flows-perl-to-typescript.md`, option A). Two questions were asked, one at a time.

## Story

A contributor who runs `tests/mutate.sh` should need only what the rest of the repo needs: Node and `npm ci`. Perl is the last other tool, and it appears in two lines. The breaks must still break exactly the same text.

## Existing behavior

- `tests/mutate.sh` copies the project, runs the tests once, then applies each break to a copy with `perl -0pi -e "$sub" file`, runs the tests and prints CAUGHT, SURVIVED, NOCHANGE or NOFILE.
- A step in `specs/steps/mutate.steps.ts` runs the same Perl line to check that every break in a kept file still changes the file it names.
- A break is one tab-separated line: name, file, substitution, and an optional `equivalent` mark. 84 breaks in 7 files. All 84 are `s/pattern/replacement/` (50) or `s~pattern~replacement~` (34). One has the flag `g`. Five use `$1` in the replacement. None uses a feature only Perl has (`\z`, `\A`, `\Q`, lookbehind, `\K`, `/e`).
- Bash `read` with a tab separator merges empty fields, so a break line cannot hold an empty column. The substitution has to stay one field.

## Agreed examples

- **E1** Each of the 84 breaks, applied to its real file by the Perl line and by the new script, gives the same broken file. Checked once, before the Perl line is deleted. A break that differs is rewritten for the new script and checked again.
- **E2** A substitution that matches nothing leaves the file as it was. The runner reports NOCHANGE, as before.
- **E3** Without a flag only the first match changes. The flags `g`, `i`, `m` and `s` do what they do in JavaScript.
- **E4** In the replacement, `$1` to `$9` are the captures, `\n` is a newline, `\t` a tab, `\\` a backslash, `\$` a dollar sign, and a backslash before the delimiter is the delimiter. Nothing else is special.
- **E5** A substitution that is not valid (no delimiter, an unclosed part, an unknown flag, a pattern that is not a regex) leaves the file as it was, says why, and the runner reports NOCHANGE with the reason.
- **E6** `tests/mutate.sh` run without `npm ci` stops before copying anything and says "run `npm ci` first".
- **E7** The step that checks that every break still changes its file uses the same script.
- **E8** The scenarios of `tests/mutate.sh` pass unchanged, and no Perl is left in `tests/` or `specs/`.

## Decisions

| # | Question | Decision | Reason |
|---|----------|----------|--------|
| 1 | What moves? | Only the step that applies a break. `tests/mutate.sh` stays bash and calls a small TypeScript script in place of `perl -0pi`. | The maintainer chose it. The dependency to remove is Perl, not bash. The runner's parallel jobs, copies and exit codes are proven by their own scenarios. |
| 2 | How is a break written? | The same single field, `s<delimiter>pattern<delimiter>replacement<delimiter>flags`, read as a JavaScript regex substitution. | The maintainer chose it. The 84 breaks change little. One field keeps bash `read` working. |
| 3 | How do we know the 84 breaks still break the same text? | A one-time comparison of the broken file from the Perl line and from the new script, for all 84, before the Perl line goes. A difference is fixed by rewriting the break, not by bending the script. Result recorded here. | The builder chose it. Perl and JavaScript differ at the edges (`$` before a final newline, escapes in the replacement). The two broken files can be compared directly, so this is cheap and complete. |
| 4 | Where does the script live and how does it run? | `tests/apply-break.ts`, run with the repo's own `node_modules/.bin/tsx`, from the repo that holds `mutate.sh`, also when `--root` names another project. | The builder chose it. The script is part of the runner, not of the project under test. |
| 5 | What when `npm ci` has not run? | `mutate.sh` checks for the tool first, before it copies anything, and stops with one line. | The builder chose it. The same rule as `flows/run.sh`. It fails before a long run starts. |
| 6 | How are the escapes in the replacement read? | Exactly the set in E4. | The builder chose it. It keeps the meaning that the existing breaks were written with. JavaScript's own replacement rules would read `\n` as two characters. |
| 7 | How is an invalid substitution reported? | The script exits with status 2 and a reason. The runner prints NOCHANGE and the reason. The check step reports the break as stale. | The builder chose it. No new status for the runner to learn. A bad break was never "caught". |
| 8 | Does the new script get breaks of its own? | Yes: a small break file `tests/mutations/apply-break.tsv`, added to the areas the runner scenarios check, plus a break for the `npm ci` check in `tests/mutations/mutate.tsv`. | The builder chose it. The repo's rule is that a change has a test that notices when it is broken. |

## Existing users

- The runner and the break files are at the repo root, not in the plugin. No installed project has them. Nothing changes for a project that uses the plugin.
- A contributor who runs `tests/mutate.sh` needs `npm ci`. The test suite already asks for it, so nobody new is affected.
- Perl is no longer needed anywhere in the repo.

## First run

A fresh checkout without `npm ci` that runs `tests/mutate.sh` sees one line: "run `npm ci` first". After `npm ci` the run is as before.

## Exclusions

- The runner stays bash: the parallel jobs, `rsync`, the copies, the exit codes and the output.
- No break is added, removed or made stronger, except the two kinds in decision 8. A break that has to be rewritten for E1 keeps its name and its meaning.
- No new status in the runner output.
- The plugin folder and the flow scripts: unchanged.

## Risks

- A break that differs between Perl and JavaScript and is rewritten could change what it tests. The runs of `tests/mutate.sh` on every changed file are the check: a break that was caught before must be caught after, and the three marked equivalent stay equivalent.
- Files with odd bytes: the script reads and writes text. A text file that is not valid UTF-8 would change on a round trip. The comparison in E1 covers the files the breaks name.

## Not proven by this change

That the breaks are good ones. This change proves only that they break the same text as before.

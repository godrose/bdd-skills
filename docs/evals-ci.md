# Evals in CI

The plugin evals run in GitHub Actions from `.github/workflows/evals.yml`. How to run them by hand is in `evals/README.md`.

## In CI

`.github/workflows/evals.yml` runs four of the five cases: `init-audit`, `design-vague-ac`, `triage-approval-gate` and `run-zero-tests`. It has two triggers.

- **Manual (`workflow_dispatch`):** run it from the Actions tab. Do this first. It is the only way to learn whether the login, the Linux sandbox and the grants work on a runner, because the docs do not cover `claude plugin eval` in CI.
- **Nightly (`schedule`):** it does nothing until you set the repository variable `EVALS_NIGHTLY` to `true`. Set it after one good manual run.

Setup:

1. Run `claude setup-token` on your machine and copy the token it prints. It lasts one year, and it is tied to the subscription of the person who ran it. It can only make model requests.
2. Add it as the repository secret `CLAUDE_CODE_OAUTH_TOKEN`.
3. Run the workflow by hand and read the summary. A green run prints one line. A failing run lists the failed graders, and the `eval-results` artifact (the agent answers) is uploaded only when the job fails.
4. Set `EVALS_NIGHTLY` to `true`.

The runs use that subscription, not API billing, so they cost no extra money. They do draw on the plan's usage limits, shared with your own Claude Code use. The workflow caps one case at $1 of notional cost (`--max-cost-usd`) and fails below a mean score of 0.8 (`--threshold`). The workflow must not set `ANTHROPIC_API_KEY`: the docs rank it above the token.

The token expires after a year. Renew it with `claude setup-token` and replace the secret before it does. GitHub runs scheduled workflows only from the default branch, attributes them to whoever last changed the `cron` line, and disables them in public repositories after 60 days without activity.

`design-lint-draft` stays out of CI. It needs plain `Bash`, and the agent's shell receives `ANTHROPIC_`-prefixed and `CLAUDE_CODE_` variables (tested with a canary variable on 2026-11-05), so the token may be readable. Only the harness variables were seen in the test, not the token itself. The narrow grants of the other cases keep the same risk in a smaller form: `Bash(echo:*)` in `run-zero-tests` could print it. Only our own fixtures and plugin text drive the agent, and the workflow does not run on pull requests. The artifact holds prompts and outputs, is kept for 14 days and is uploaded only when the job fails.

Not verified: that `claude plugin eval` accepts `CLAUDE_CODE_OAUTH_TOKEN` and passes it to its child sessions. The docs do not cover `plugin eval` in CI. The first manual run decides it.

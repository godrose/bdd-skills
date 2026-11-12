@evals
Feature: The nightly evals workflow is manual first, narrow and quiet

  Decision (2026-11-11): The workflow has no em-dash is checked on the whole file. Why: the old check looked at lines added since main, and the bash file that held it is being replaced. The file has none today.
  Decision (2026-11-11): The workflow still names design-lint-draft but keeps it out of the loop. Why: the old file checked both. It needs plain Bash, which the nightly does not grant.
  Decision (2026-11-11): The check that the workflow contains evals/run.sh is not written again. Why: layout-wiring.feature already has it.

  Scenario: The workflow runs the cases through the runner script, not the eval tool directly
    Given the file ".github/workflows/evals.yml"
    Then it does not contain "claude plugin eval plugin"

  Scenario: The nightly loop holds five cases
    Given the file ".github/workflows/evals.yml"
    Then it contains "for c in init-audit design-vague-ac triage-approval-gate run-zero-tests deliver-first-gate"

  Scenario: The lint case stays out of the nightly loop
    Given the file ".github/workflows/evals.yml"
    Then it contains "design-lint-draft"
    And it does not contain "for c in init-audit design-vague-ac triage-approval-gate run-zero-tests design-lint-draft"

  Scenario: The workflow starts by hand and on a schedule gated by a repo variable
    Given the file ".github/workflows/evals.yml"
    Then it contains:
      | workflow_dispatch: |
      | schedule:          |
      | cron:              |
      | vars.EVALS_NIGHTLY |

  Scenario: The workflow trusts the plugin, caps the cost and sets a threshold
    Given the file ".github/workflows/evals.yml"
    Then it contains:
      | --trust-plugin  |
      | --max-cost-usd  |
      | --threshold     |
      | --ablation none |

  Scenario: The workflow has a read-only token, a time limit and an artifact
    Given the file ".github/workflows/evals.yml"
    Then it contains:
      | secrets.CLAUDE_CODE_OAUTH_TOKEN |
      | contents: read                  |
      | timeout-minutes                 |
      | upload-artifact                 |

  Scenario: The workflow does not run on pull requests
    Given the file ".github/workflows/evals.yml"
    Then it does not contain "pull_request"

  Scenario: The workflow does not run on pushes
    Given the file ".github/workflows/evals.yml"
    Then it does not contain "push:"

  Scenario: The workflow uses the subscription token and no API key
    Given the file ".github/workflows/evals.yml"
    Then it does not contain "ANTHROPIC_API_KEY"

  Scenario: The token is set on the step that runs the evals
    Given the file ".github/workflows/evals.yml"
    Then it does not set "CLAUDE_CODE_OAUTH_TOKEN" above the step level

  Scenario: The workflow grants no plain Bash to the agent
    Given the file ".github/workflows/evals.yml"
    Then it does not contain "--allow-tools Write Edit Bash "
    And it contains "Bash(sh ./fake-test.sh:*)"

  Scenario: The workflow has the sandbox backend before a shell tool is granted
    Given the file ".github/workflows/evals.yml"
    Then it contains:
      | bubblewrap                            |
      | socat                                 |
      | apparmor_restrict_unprivileged_userns |
      | bwrap --version                       |

  Scenario: The workflow is quiet when green
    Given the file ".github/workflows/evals.yml"
    Then it contains:
      | id: evals      |
      | EVAL_OUTCOME   |
      | if: failure()  |
      | All            |
      | Failed graders |
    And it has 1 lines containing "if: always()"

  Scenario: The workflow has no em-dash
    Given the file ".github/workflows/evals.yml"
    Then it has no em-dash

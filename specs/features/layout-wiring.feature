@layout
Feature: The CI, the evals and the installer know about the plugin folder

  How to run, check and evaluate the plugin is written down and wired into CI. The CI
  setup for the evals lives outside the plugin folder. The installer reads from plugin/.

  Scenario: The eval results folder stays ignored
    Given the file ".gitignore"
    Then it contains "evals/results/"

  Scenario: The contributor guide says how to run the plugin from a clone
    Given the contributor guide
    Then it contains "claude --plugin-dir <this repo>/plugin"

  Scenario: The README says how to run and validate the plugin from a clone
    Given the README
    Then it contains:
      | claude --plugin-dir <clone>/plugin |
      | claude plugin validate plugin      |

  Scenario: The evals workflow runs the eval runner
    Given the file ".github/workflows/evals.yml"
    Then it contains "evals/run.sh"

  Scenario: The evals guide names the eval runner
    Given the file "evals/README.md"
    Then it contains "evals/run.sh"

  Scenario: The CI workflow validates the plugin folder and pins the claude-code version
    Given the CI workflow
    Then it contains "claude plugin validate plugin"
    And it contains "@anthropic-ai/claude-code@"

  Scenario: The CI token setup is not named inside the plugin folder
    Given the plugin folder
    Then no file in it names any of:
      | setup-token             |
      | CLAUDE_CODE_OAUTH_TOKEN |

  Scenario: The eval CI setup guide exists outside the plugin folder
    Given the repository
    Then the repo has these files:
      | docs/evals-ci.md |

  Scenario: The evals guide points to the eval CI setup guide
    Given the file "evals/README.md"
    Then it contains "docs/evals-ci.md"

  Scenario: The docs index lists the eval CI setup guide
    Given the docs index
    Then it contains "evals-ci.md"

  Scenario: The installer reads the plugin from the plugin folder
    Given the installer
    Then it reads the plugin from the plugin folder of its source

  Scenario: The installer says so when the plugin folder is missing
    Given the installer
    Then it says "no plugin/ folder" when the plugin folder is missing

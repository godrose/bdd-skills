@evals
Feature: evals/run.sh builds a temporary plugin copy with the cases inside it

  Decision (2026-11-11): The run uses a stand-in for the eval tool, first on the path, that lists what it would read. Why: the old file did the same, and a real run is excluded.
  Decision (2026-11-11): The text of the script is pinned in two scenarios and the behavior in three. Why: the old file pinned the text before it ran the script.
  Decision (2026-11-12): Added from the mutation survivors of the eval checks. Why: the stand-in recorded its arguments, and the status and the results of the script were never read.

  Scenario: The script calls the eval tool
    Given the file "evals/run.sh"
    Then it contains "claude plugin eval"

  Scenario: The script works in a temporary folder
    Given the file "evals/run.sh"
    Then it contains "mktemp -d"

  Scenario Outline: Every case folder is placed under the evals folder of the plugin copy
    When the eval runner is run with a stand-in for the eval tool
    Then the stand-in saw "<case>" in the evals folder of the plugin copy

    Examples:
      | case                 |
      | init-audit           |
      | design-vague-ac      |
      | triage-approval-gate |
      | run-zero-tests       |
      | design-lint-draft    |
      | deliver-first-gate   |

  Scenario: No file of a case is copied into the evals folder directly
    When the eval runner is run with a stand-in for the eval tool
    Then the stand-in saw no case file directly in the evals folder of the plugin copy

  Scenario: The plugin itself is copied
    When the eval runner is run with a stand-in for the eval tool
    Then the stand-in saw "commands" in the plugin copy


  Scenario: The options of the caller reach the eval tool after the plugin copy
    When the eval runner is run with a stand-in for the eval tool
    Then the stand-in was called with "plugin eval"
    And the stand-in was called with "/plugin --runs 1"

  Scenario: The script ends with the status of the eval tool
    When the eval runner is run with a stand-in that fails with status 3
    Then the script exits with status 3

  Scenario: A failed eval run still keeps its results
    When the eval runner is run with a stand-in that fails with status 3
    Then the result folder of the stand-in is in the evals results of the repo

  Scenario: The results of a good run are kept
    When the eval runner is run with a stand-in that leaves a result folder
    Then the script exits with status 0
    And the result folder of the stand-in is in the evals results of the repo

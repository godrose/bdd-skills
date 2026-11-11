@deliver-text
Feature: The deliver command says where each answer is recorded

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: Answers that shaped a scenario are recorded as decision lines
    Given the plugin command "deliver"
    Then it contains "Decision (YYYY-MM-DD)"

  Scenario: Exclusions and removals go in the out-of-scope file, one line each
    Given the plugin command "deliver"
    Then it contains:
      | out_of_scope_file |
      | excluded:         |
      | removed:          |
      | revisit when      |

  Scenario: Each exclusion is written when the checklist is approved
    Given the plugin command "deliver"
    Then it contains "Write each exclusion when the product manager approves the checklist"

  Scenario: A line already written is never rewritten, and a reversal leaves the old entry
    Given the plugin command "deliver"
    Then it contains:
      | Never rewrite a line that is already there |
      | leave the old entry                        |

  Scenario: Deleted features are looked for in local git only
    Given the plugin command "deliver"
    Then it contains:
      | git log --diff-filter=D |
      | shallow                 |
    Given the plugin command "discover"
    Then it contains "git log --diff-filter=D"

  Scenario: A missing decision log script is reported
    Given the plugin command "deliver"
    Then it contains "Nothing was recorded"

  Scenario: A tracker key with no requirements-sync skill gets a question for the text
    Given the plugin command "deliver"
    Then it contains:
      | requirements-sync |
      | ask for the text  |

@skills-text
Feature: The reconcile command runs the script, reports and never edits

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The reconcile command runs the script, reports and never edits
    Given the plugin command "reconcile"
    Then it contains:
      | decisions.sh check  |
      | decisions.sh show   |
      | report, not a sync  |
      | never edits         |
      | contradict          |
      | audit               |
      | jq                  |
      | legacy              |
      | decision_log        |
    And it contains "--base"

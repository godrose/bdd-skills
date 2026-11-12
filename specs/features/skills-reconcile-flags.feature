@skills-text
Feature: The reconcile command passes its options to the script

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario Outline: The reconcile text names the <flag> option
    Given the plugin command "reconcile"
    Then it contains "<flag>"

    Examples:
      | flag             |
      | --planned-tag    |
      | --manual-only-tag |
      | --blocked-tag    |
      | --scope          |
      | --planned-dir    |
      | --manual-only-dir |

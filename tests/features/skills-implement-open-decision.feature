@skills-text
Feature: The implement command shows an open decision with what was found and the options

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: A stop shows what was found and the options
    Given the plugin command "implement"
    Then it contains:
      | Open decision: |
      | Found:         |
      | Options:       |

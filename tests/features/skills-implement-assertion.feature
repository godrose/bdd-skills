@skills-text
Feature: The implement command stops on a reused assertion that does not fit

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: A reused assertion that does not fit stops, and approved data is not edited
    Given the plugin command "implement"
    Then it contains:
      | assertion does not fit                |
      | Do not edit approved scenario data    |

@skills-text
Feature: The implement command does not count a run of zero tests as a pass

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command says that no tests ran is not a pass
    Given the plugin command "implement"
    Then it contains:
      | no tests ran                |
      | at least one executed test  |

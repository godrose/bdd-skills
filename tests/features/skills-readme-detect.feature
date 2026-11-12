@skills-text
Feature: The README documents init --detect

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The README documents init --detect
    Given the README
    Then it contains:
      | `/bdd:init --detect`                         |
      | writes only the rows you approve             |
      | never changes a row that already has a value |
      | never runs your commands                     |
      | unknown                                      |

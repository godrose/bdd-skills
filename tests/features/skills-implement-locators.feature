@skills-text
Feature: The implement command scopes an ambiguous locator and does not settle it with first

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: An ambiguous locator is scoped, not settled with .first()
    Given the plugin command "implement"
    Then it contains:
      | Scope the locator to the element you mean                                      |
      | Use `.first()` only when the first match is part of the behavior being tested  |
      | hide the ambiguity                                                             |
    And it does not contain "Use `.first()` on locators that may match multiple elements"

@skills-text
Feature: The implement command does not pass the scenario tag as a Tag field

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The command does not pass the scenario tag as a Tag field
    Given the plugin command "implement"
    Then it does not contain "Tag: <scenario-tag>"

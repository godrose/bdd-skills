@skills-text
Feature: The design command does not go back to flagging assumptions first

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed an earlier rule to flag a vague story before designing. Why: the designer now lists its assumptions and goes on.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The old flag-first text is gone
    Given the plugin command "design"
    Then it does not contain "flag it for the user before designing scenarios"

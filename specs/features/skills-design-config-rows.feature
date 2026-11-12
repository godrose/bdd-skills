@skills-text
Feature: The design command does not default to the manual tag

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): size gate and unautomated_tag are each checked once. Why: a duplicate adds no check.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The command does not default to the manual tag
    Given the plugin command "design"
    Then it does not contain "default `@manual`"

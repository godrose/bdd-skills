@skills-text
Feature: The implement command does not go back to the old tag defaults

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed a rule that removed the unautomated tag when a scenario passes. Why: the tag is removed only after the verifier passes.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The tag is not removed the moment a scenario passes
    Given the plugin command "implement"
    Then it does not contain "When a scenario from an approved spec passes, remove the unautomated tag"

  Scenario: The command does not default to the manual tag
    Given the plugin command "implement"
    Then it does not contain "default `@manual`"

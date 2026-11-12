@skills-text
Feature: The run command does not point at an install command

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The implement command is not checked here. Why: it comes in the next pull request.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The run command does not point at an install command
    Given the plugin command "run"
    Then it does not contain "Run the install command if missing"

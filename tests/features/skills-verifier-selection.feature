@skills-text
Feature: The verifier agent no longer reports a Tag field

  These scenarios read the text of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The checks on the implement command that go with these are not written here. Why: they come in the next pull request.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The agent no longer reports a Tag field
    Given the file "plugin/agents/verifier.md"
    Then it does not contain "**Tag:**"

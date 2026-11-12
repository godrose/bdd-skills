@skills-text
Feature: The run command and the verifier agent do not mention deliver

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario Outline: The <file> text does not mention deliver
    Given the file "<file>"
    Then it does not contain "deliver"

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |

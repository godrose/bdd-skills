@skills-text
Feature: A generate row with no command is skipped, not run

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario Outline: The <file> text skips an empty generate row and does not call it a failure
    Given the file "<file>"
    Then it contains:
      | _(not needed)_  |
      | skip this step  |
      | not a failure   |

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |

@skills-text
Feature: The verifier agent selects scenarios by tag, name, file or all

  These scenarios read the text of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The checks on the implement command that go with these are not written here. Why: they come in the next pull request.

  Scenario: The agent takes a selection and reports it
    Given the file "plugin/agents/verifier.md"
    Then it contains:
      | By: tag \| name \| file \| all |
      | Select:                        |
      | **Selection:**                 |
      | unknown field Tag              |
      | name matched                   |

  Scenario: The agent no longer reports a Tag field
    Given the file "plugin/agents/verifier.md"
    Then it does not contain "**Tag:**"

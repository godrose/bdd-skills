@skills-text
Feature: The design command states its modes, its stops and its approvals

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): specify-only is not checked alone. Why: --specify-only implies it.

  Scenario: The command names its modes and the absent workflow_mode
    Given the plugin command "design"
    Then it contains:
      | --specify-only                    |
      | specify-and-implement             |
      | discovery pack                    |
      | does not invoke the implementer   |
      | unautomated tag                   |
      | If `workflow_mode` is absent      |

  Scenario: The command stops at the approved spec and says what it does when it is not ready
    Given the plugin command "design"
    Then it contains:
      | Readiness says it is not ready |
      | there are no results to push   |
      | stop at the approved spec      |

  Scenario: The command takes the examples as approved and records decisions
    Given the plugin command "design"
    Then it contains:
      | counts as the approval of the examples |
      | Decision (YYYY-MM-DD)                  |
      | go-ahead                               |

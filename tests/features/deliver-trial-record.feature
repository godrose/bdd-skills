@deliver-text
Feature: The trial record shows how a product manager works with deliver

  These scenarios read the text of the trial record. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The trial record exists and says who played the product manager
    Given the repository
    Then the repo has these files:
      | docs/trials/2026-11-09-deliver-pm-session.md |
    Given the file "docs/trials/2026-11-09-deliver-pm-session.md"
    Then it contains:
      | the plugin author played the product manager |
      | Not run through the command itself           |

  Scenario: It shows the dialogue and the pushback
    Given the file "docs/trials/2026-11-09-deliver-pm-session.md"
    Then it contains:
      | One question at a time                                |
      | Where the product manager was confused or pushed back |

  Scenario: It has no local path and no em-dash
    Given the file "docs/trials/2026-11-09-deliver-pm-session.md"
    Then it does not contain "/Users/"
    And it has no em-dash

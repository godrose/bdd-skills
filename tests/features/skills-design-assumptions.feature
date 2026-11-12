@skills-text
Feature: The design command lists its assumptions and does not choose silently

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed an earlier rule to flag a vague story before designing. Why: the designer now lists its assumptions and goes on.

  Scenario: The designer lists its assumptions and does not stop to ask
    Given the plugin command "design"
    Then it contains:
      | List assumptions                              |
      | more than one distinct value                  |
      | Do not stop to ask                            |
      | values unknown, please confirm                |
      | Assumptions: none                             |
      | Omit this section when there are none         |
      | Silently picking one meaning                  |

  Scenario: The old flag-first text is gone and a settled value is not listed
    Given the plugin command "design"
    Then it does not contain "flag it for the user before designing scenarios"
    And it contains "do not list it"

  Scenario: The assumptions text comes in order
    Given the plugin command "design"
    Then it mentions these in this order:
      | List assumptions                      |
      | Assumptions: none                     |
      | Omit this section when there are none |

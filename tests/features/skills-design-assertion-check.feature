@skills-text
Feature: The design command checks that a reused Then step makes the claim the scenario needs

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command checks the assertion of a reused Then step
    Given the plugin command "design"
    Then it contains:
      | Pass C                        |
      | assertion check               |
      | \| Asserts \|                 |
      | assertion unknown             |
      | assertion not checkable yet   |
      | The person chooses            |
      | never changes fixture data    |
      | Same words means same claim   |

  Scenario: Pass C comes after Pass B
    Given the plugin command "design"
    Then it mentions these in this order:
      | Pass B |
      | Pass C |

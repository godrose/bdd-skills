@skills-text
Feature: The design command checks that a scenario asserts what its title claims

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command checks the title against the assertions
    Given the plugin command "design"
    Then it contains:
      | Pass D                                         |
      | title check                                    |
      | \| Claims \|                                   |
      | claim unchecked                                |
      | names an exact value                           |
      | narrow the title                               |
      | only for the scenarios drafted in this run     |
      | never changes a title                          |
      | Asserting less than the title claims           |

  Scenario: Pass D comes after Pass C
    Given the plugin command "design"
    Then it mentions these in this order:
      | Pass C |
      | Pass D |

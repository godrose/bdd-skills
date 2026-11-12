@skills-text
Feature: The design command has its headings and writes the summary

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command has its five headings
    Given the plugin command "design"
    Then it contains:
      | Story to scenarios         |
      | Cases included             |
      | Cases deliberately excluded |
      | New terms                  |
      | Step status                |

  Scenario: The command writes the summary file and lists undefined steps
    Given the plugin command "design"
    Then it contains:
      | undefined steps                  |
      | existing (not yet automated)     |
      | .spec-summary.md                 |
      | unautomated_tag                  |

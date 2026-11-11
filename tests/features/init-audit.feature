@plugin-text
Feature: The init command audits existing values, read only, every time

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.

  Scenario: Detect audits existing values, read only
    Given the plugin command "init"
    Then it contains:
      | ### Audit                       |
      | Always run the audit            |
      | one line                        |
      | not checked                     |
      | header text                     |
      | test filters                    |
      | does not resolve                |
      | Skill Roles                     |
      | Never edit a value in the audit |

  Scenario: The audit does not stop when no row is a placeholder
    Given the plugin command "init"
    Then it does not contain "If no row is a placeholder, say so and stop."

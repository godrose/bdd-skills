@skills-text
Feature: The implement command stops without a config and takes several step folders

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: A missing config stops the command
    Given the plugin command "implement"
    Then it contains:
      | does not exist, say so and stop |
      | `bdd-config.template.md`        |

  Scenario: The steps folder takes several paths
    Given the plugin command "implement"
    Then it contains "comma-separated"

@skills-text
Feature: The implement command is framework neutral and gates UI advice by the config

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: UI and language advice applies only when the config sets it
    Given the plugin command "implement"
    Then it contains:
      | apply when the config sets |
      | visual-debug flag          |
      | page objects or helpers    |
      | explicit file extensions   |
      | UI projects only           |
      | the system under test      |
      | no UI evidence             |

  Scenario: The command has no UI-first advice
    Given the plugin command "implement"
    Then it does not contain:
      | explore UI, discover selectors |
      | exploring the actual UI state  |
      | plus `--headed`                |
      | (without `--headed`)           |
      | Which advice applies           |

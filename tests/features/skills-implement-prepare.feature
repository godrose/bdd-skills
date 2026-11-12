@skills-text
Feature: The implement command runs the prepare row before generate and test

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command runs prepare when it has a command and stops when it fails
    Given the plugin command "implement"
    Then it contains:
      | **prepare**                                     |
      | If the row is absent, empty                     |
      | If **prepare** fails, report the error and stop |
      | Do not run generate or test                     |

  Scenario: The command runs prepare before generate
    Given the plugin command "implement"
    Then it mentions these in this order:
      | Run the **prepare** command      |
      | Ensure the **generate** command  |

  Scenario: The command names the order of the three commands
    Given the plugin command "implement"
    Then it contains "the **prepare** command, then the **generate** command, then the **test** command"

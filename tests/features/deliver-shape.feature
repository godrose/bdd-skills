@deliver-text
Feature: The deliver command has a shape and names the commands it composes

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command exists, has a description and has no em-dash
    Given the repository
    Then the repo has these files:
      | plugin/commands/deliver.md |
    Given the plugin command "deliver"
    Then it contains:
      | description: " |
    And it has no em-dash

  Scenario: The four steps come in order
    Given the plugin command "deliver"
    Then it mentions these in this order:
      | #### Step 1: Discover  |
      | #### Step 2: Design    |
      | #### Step 3: Implement |
      | #### Step 4: Run       |

  Scenario: The command names the four commands it composes
    Given the plugin command "deliver"
    Then it contains:
      | bdd:discover  |
      | bdd:design    |
      | bdd:implement |
      | bdd:run       |

  Scenario: A missing config stops it, as in the other commands
    Given the plugin command "deliver"
    Then it contains:
      | does not exist, say so and stop                                                          |
      | `bdd-config.template.md`                                                                 |
      | > Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`   |

  Scenario: The size gate lets a trivial change skip discovery
    Given the plugin command "deliver"
    Then it contains:
      | size gate              |
      | say so in one sentence |

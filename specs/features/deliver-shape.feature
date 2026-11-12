@deliver-text
Feature: The deliver command exists and stops without a config

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): After the approach review only the existence check and the missing-config stop stay. Why: the config stop is a contract with the template. The step order, the four commands and the size gate were wording checks.

  Scenario: The command exists, has a description and has no em-dash
    Given the repository
    Then the repo has these files:
      | plugin/commands/deliver.md |
    Given the plugin command "deliver"
    Then it contains:
      | description: " |
    And it has no em-dash

  Scenario: A missing config stops it, as in the other commands
    Given the plugin command "deliver"
    Then it contains:
      | does not exist, say so and stop                                                          |
      | `bdd-config.template.md`                                                                 |
      | > Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`   |

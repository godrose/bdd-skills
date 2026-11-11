@deliver-text
Feature: The deliver command asks for approval twice and writes nothing before the second

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The checklist needs approval before the next step
    Given the plugin command "deliver"
    Then it contains "Do not go on until the product manager has approved the checklist"

  Scenario: No feature file is written before the go-ahead, and either person can give it
    Given the plugin command "deliver"
    Then it contains:
      | No `.feature` file is written before the go-ahead |
      | either person                                     |

  Scenario: The checklist approval comes before the go-ahead
    Given the plugin command "deliver"
    Then it mentions these in this order:
      | approved the checklist                            |
      | No `.feature` file is written before the go-ahead |

  Scenario: Specify-only stops after the go-ahead
    Given the plugin command "deliver"
    Then it contains:
      | specify-only                  |
      | specified and not implemented |

@deliver-text
Feature: The deliver command sorts a stop into a product decision or a technical stop

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: A product decision is asked at once
    Given the plugin command "deliver"
    Then it contains:
      | A product decision is asked at once  |
      | ask one question about that behavior |
      | record the answer                    |

  Scenario: A technical stop is parked and the independent examples go on
    Given the plugin command "deliver"
    Then it contains:
      | A technical stop is parked |
      | a step failed three times  |
      | independent examples go on |
      | developer note             |

  Scenario: An approved scenario is never changed to pass a check
    Given the plugin command "deliver"
    Then it contains "never change an approved scenario or its expected values"

  Scenario: The implementer is not invoked twice for a scenario
    Given the plugin command "deliver"
    Then it contains "do not invoke it again for that scenario"

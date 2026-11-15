@flow-deliver @flow-build-order
Feature: A deliver run records its calls, and the rule build-order counts the order of the build

  Decision (2026-11-15): Each turn is run with the stream output and the raw events are saved next to the turn text. Why: the plain output keeps only the text, so the order of the calls cannot be seen. Chosen by the builder over reading the session file of Claude Code.
  Decision (2026-11-15): The rule counts the new scenarios that still had no steps (undefined) in the last run of the whole suite before the first application edit. None is all-first, and one or more is per-scenario. Why: the two orders differ at that moment in how many new scenarios have steps. The count of failures was tried first and a real per-scenario run broke it, because scenarios share steps and one new step turns several of them red at once. Replaces the earlier decision that counted failures.
  Decision (2026-11-15): The expected order is the flag in the story, else the row of the fixture config, else all-first. Why: it is the order of the plugin text, and the default of the plugin.
  Decision (2026-11-15): A run without events, with fewer than two new scenarios, without an application edit, or without a run of the whole suite before that edit is not counted. Why: a recorded run of the older kind is not a break, nothing can be told apart without a build, and a run of one scenario by name says nothing about the others.

  Scenario: Each turn is run with the stream output
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then call 1 to the assistant contains:
      | --output-format stream-json |
      | --verbose                   |

  Scenario: The events of a turn are saved next to its text
    Given the assistant says the checklist and then the scenarios
    And the assistant makes these calls while it says message 3:
      | tool | input                  | result |
      | Edit | steps/loans.steps.js   | ok     |
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the file "turn-03-events.jsonl" of the run contains:
      | "name":"Edit" |

  Scenario: The expected order and the new scenarios are saved in the record of the run
    Given the assistant says the checklist and then the scenarios
    And the run uses a story that holds:
      """
      --build-order per-scenario A late loan shows its days late.
      """
    And the assistant adds a feature file with 3 scenarios while it says message 3
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the file "meta.json" of the run contains:
      | "build_order": "per-scenario" |
      | "new_scenarios": 3            |

  Rule: With all-first, every new scenario has steps when the first application edit is made

    Scenario: Every new scenario had steps before the build
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                                    |
        | Edit | steps/loans.steps.js | ok                                        |
        | Bash | npm test             | 4 scenarios (3 failed, 1 passed)          |
        | Edit | src/pages/loans.js   | ok                                        |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is held
      And the detail of the rules mentions "0 of 3"

    Scenario: Some new scenarios had no steps before the build
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (2 failed, 1 undefined, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is broken
      And the detail of the rules mentions "all-first"
      And the detail of the rules mentions "1 of 3"

  Rule: With per-scenario, some new scenarios still have no steps when the first application edit is made

    Scenario: The next scenarios still had no steps at the first build
      Given the assistant says the checklist and then the scenarios
      And the run uses a story that holds:
        """
        --build-order per-scenario A late loan shows its days late.
        """
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (1 failed, 2 undefined, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is held

    Scenario: All new scenarios had steps at once, so the build came late
      Given the assistant says the checklist and then the scenarios
      And the run uses a story that holds:
        """
        --build-order per-scenario A late loan shows its days late.
        """
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (3 failed, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is broken
      And the detail of the rules mentions "per-scenario"

    Scenario: The row of the config of the fixture sets the order when the story has no flag
      Given the build order row of the fixture config in a copy of the harness is "per-scenario"
      And the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (3 failed, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness of the copy plays the conversation
      Then the rule "build-order" is broken

  Rule: The last run of the whole suite before the first application edit is the one that counts

    Scenario: A later run replaces the count of an earlier one
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Bash | npm test             | 4 scenarios (1 failed, 2 undefined, 1 passed) |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (3 failed, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is held

    Scenario: A run of one scenario by name does not count
      Given the assistant says the checklist and then the scenarios
      And the run uses a story that holds:
        """
        --build-order per-scenario A late loan shows its days late.
        """
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                                |
        | Edit | steps/loans.steps.js | ok                                    |
        | Bash | npm test             | 4 scenarios (1 failed, 2 undefined, 1 passed) |
        | Bash | npm test             | 1 scenario (1 failed)                 |
        | Edit | src/pages/loans.js   | ok                                    |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is held

  Rule: Only an edit of application code starts the build

    Scenario Outline: An edit under <where> is not an application edit
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input   | result                           |
        | Bash | npm test | 4 scenarios (1 failed, 2 undefined, 1 passed) |
        | Edit | <path>  | ok                               |
        | Bash | npm test | 4 scenarios (3 failed, 1 passed) |
        | Edit | src/pages/loans.js | ok                  |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is held

      Examples:
        | where    | path                      |
        | steps    | steps/loans.steps.js      |
        | features | features/loans.feature    |
        | docs     | docs/out-of-scope.md      |
        | data     | data/loans-check.json     |

  Rule: Some runs are not counted

    Scenario: No application edit was made
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Edit | steps/loans.steps.js | ok                               |
        | Bash | npm test             | 4 scenarios (1 failed, 2 undefined, 1 passed) |
        | Edit | steps/more.steps.js  | ok |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is not counted

    Scenario: Only one scenario is new
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 1 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                           |
        | Bash | npm test             | 2 scenarios (1 failed, 1 passed) |
        | Edit | src/pages/loans.js   | ok                               |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is not counted

    Scenario: No run of the whole suite came before the build
      Given the assistant says the checklist and then the scenarios
      And the assistant adds a feature file with 3 scenarios while it says message 3
      And the assistant makes these calls while it says message 3:
        | tool | input                | result                |
        | Edit | steps/loans.steps.js | ok                    |
        | Bash | npm test             | 1 scenario (1 failed) |
        | Edit | src/pages/loans.js   | ok                    |
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is not counted

    Scenario: The run holds no calls
      Given the assistant says the checklist and then the scenarios
      And the assistant ends with the clean report
      When the harness plays the conversation
      Then the rule "build-order" is not counted

  Scenario: The report of the harness shows the rule
    Given the assistant says the checklist and then the scenarios
    And the assistant adds a feature file with 3 scenarios while it says message 3
    And the assistant makes these calls while it says message 3:
      | tool | input                | result                           |
      | Edit | steps/loans.steps.js | ok                               |
      | Bash | npm test             | 4 scenarios (3 failed, 1 passed) |
      | Edit | src/pages/loans.js   | ok                               |
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the report of the harness contains "build-order"

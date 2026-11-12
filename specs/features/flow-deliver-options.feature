@flow-deliver
Feature: The options of the harness decide what the model is asked and allowed

  Decision (2026-11-11): The turn caps are text pins on flows/run.sh. Why: the old file pinned them that way, and a real run would cost a model session.

  Scenario: The first call starts /bdd:deliver with the story
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then call 1 to the assistant contains:
      | /bdd:deliver When a loan is overdue |

  Scenario: The model may run the tests and the page script
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then call 1 to the assistant contains:
      | Bash(npm test)                |
      | Bash(node src/show.js)        |
      | Bash(node src/show.js data/*) |

  Scenario: The model is given no install command
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then call 1 to the assistant does not contain:
      | npm install |
      | npm ci      |

  Scenario: The reply of the product manager reaches the next call
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then call 2 to the assistant contains:
      | Approved |

  Scenario: The turn cap for deliver is 30
    Given the file "flows/run.sh"
    Then it contains "TURNS=30"

  Scenario: The turn cap for discover is 12
    Given the file "flows/run.sh"
    Then it contains "TURNS=12"

  Scenario: Without the installed tools the harness stops at once and says to run npm ci
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the installed tools of the harness are missing
    When the harness plays the conversation
    Then the run fails
    And the output mentions "npm ci"
    And no session was started

  Scenario: Without the installed tools a report comparison stops and says to run npm ci
    Given the installed tools of the harness are missing
    And a first report that reads:
      """
      | rule | 1 of 1 |
      """
    And a second report that reads:
      """
      | rule | 1 of 1 |
      """
    When the two reports are compared
    Then the run fails
    And the output mentions "npm ci"

  Scenario: The README documents the deliver option
    Given the file "flows/README.md"
    Then it contains "--command deliver"

  Scenario: The test run does not start the harness
    Given the file "tests/run.sh"
    Then it does not contain "flows"

  Scenario: The workflows do not start the harness
    Given the workflow files
    Then none of them contains "flows/"

  Scenario: The results of the harness are not tracked
    Given the file ".gitignore"
    Then it contains "flows/results/"

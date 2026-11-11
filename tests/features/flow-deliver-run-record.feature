@flow-deliver
Feature: A run leaves a record in its folder

  Scenario: The real test output is saved
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the file "test-output.txt" of the run contains:
      | 2 scenarios (2 passed) |

  Scenario: A report that starts with Delivered ends the run
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the file "meta.json" of the run contains:
      | "finished": true |
      | "turns": 3       |

  Scenario: The report of the harness names the command, the fixture and the story
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the report of the harness contains "deliver, fixture c, story 1"

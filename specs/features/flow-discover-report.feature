@flow-discover
Feature: The report of a discover run gives counts, the breaks, turns and time, and no verdict

  Background:
    Given the harness runs discover on fixture "a"
    And the assistant says:
      """
      What exists: nothing.
      One?
      Two?
      """
    And the assistant ends with an unfinished readiness block

  Scenario: The report names the rule that broke and its count
    When the harness plays the conversation
    Then the report of the harness contains:
      | one-question |
      | 0 of 1       |

  Scenario: The report names the run and the message that broke the rule
    When the harness plays the conversation
    Then the report of the harness contains:
      | run-1     |
      | message 1 |

  Scenario: The report shows turns and time
    When the harness plays the conversation
    Then the report of the harness contains:
      | turns   |
      | seconds |

  Scenario: The report gives no verdict
    When the harness plays the conversation
    Then the report of the harness does not contain:
      | pass |
      | fail |
      | PASS |
      | FAIL |

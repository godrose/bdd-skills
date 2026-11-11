@flow-deliver
Feature: Two reports are compared side by side, with no verdict

  Decision (2026-11-11): The compare gives differences and no verdict. Why: decision 6 of the deliver flow pack, 2026-11-11-deliver-flow-runs.md.

  Background:
    Given a first report that reads:
      """
      | Rule | Runs that held it |
      |---|---|
      | one-question | 1 of 1 |
      | plain-words | 1 of 1 |
      """
    And a second report that reads:
      """
      | Rule | Runs that held it |
      |---|---|
      | one-question | 1 of 1 |
      | plain-words | 0 of 1 |
      """

  Scenario: The counts of both reports are shown
    When the two reports are compared
    Then the output mentions:
      | plain-words |
      | 1 of 1      |
      | 0 of 1      |

  Scenario: The rule that moved is marked
    When the two reports are compared
    Then the line for the rule "plain-words" is marked "moved"

  Scenario: A rule that did not move is not marked
    When the two reports are compared
    Then the line for the rule "one-question" is not marked "moved"

  Scenario: The comparison gives no verdict
    When the two reports are compared
    Then the output does not mention:
      | pass    |
      | fail    |
      | regress |
      | better  |
      | worse   |

  Scenario: A missing report is an error
    When the first report is compared with a report that does not exist
    Then the run fails

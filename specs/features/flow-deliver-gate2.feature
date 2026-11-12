@flow-deliver
Feature: A table under a developer line is developer text

  The second gate of deliver puts the step reuse table under a "For the developer" line, then a blank line, then the table. The plain-words rule reads it as developer text and keeps counting everything else.

  Decision (2026-11-12): A developer line and a table that follows it after one blank line are developer text. Why: a table needs a blank line to render, and the builder chose it. It replaces the rule that a developer line ends at the first blank line.

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A table with file names under a developer line is not a break
    Given the assistant opens with what exists and one question
    And the assistant says:
      """
      Here are the scenarios in plain words. Three steps are reused and three are new.

      For the developer: the step reuse audit.

      | Step | Status | Existing analog |
      |------|--------|-----------------|
      | `When I export the records to CSV` | exact | `steps/records.steps.js:8` |
      | `Then the CSV has 3 rows` | exact | `steps/records.steps.js:9` |

      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: A table with file names with no developer line is a break
    Given the assistant opens with what exists and one question
    And the assistant says:
      """
      Here are the scenarios in plain words.

      | Step | Status | Existing analog |
      |------|--------|-----------------|
      | `When I export the records to CSV` | exact | `steps/records.steps.js:8` |

      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is broken

  Scenario: Plain text between the developer line and the table is still counted
    Given the assistant opens with what exists and one question
    And the assistant says:
      """
      For the developer: the step reuse audit.

      The step lives in steps/records.steps.js.

      | Step | Status |
      |------|--------|
      | `When I export the records to CSV` | exact |

      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is broken

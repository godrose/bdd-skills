@flow-discover
Feature: The discover rules read the messages the way the product manager would

  Decision (2026-11-12): Added from the mutation survivors of the discover harness. Why: each scenario here fails when the matching line of `flows/rules.pl`, `flows/run.sh` is broken.
  Decision (2026-11-12): No scenario for a "Not ready" that the rule does not know, or for a command name with an underscore. Why: no input separates the two versions, so no scenario can fail.

  Decision (2026-11-12): The look-first rule also accepts an opening that says what the assistant did to look, such as "I ran", "I looked", "I checked", "I read" or "I searched". Why: a real run of deliver opened with "I ran the real export ... it exported all 4 records", which is a finding before the question, and the rule broke because the message had none of the older phrases. The rule still breaks when the question comes first.

  Background:
    Given the harness runs discover on fixture "a"

  Scenario Outline: A first message that says "<opening>" before its question
    Given the assistant says:
      """
      <opening> Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "look-first" is held

    Examples:
      | opening                        |
      | What exists: one scenario.     |
      | What I found: one scenario.    |
      | I found nothing in this project. |
      | Part of this already works.    |
      | I ran the real export on the sample data. |
      | I looked at the scenarios and the code. |
      | I checked the project for it.  |
      | I read the scenarios.          |
      | I searched the steps.          |

  Scenario: A question before what the assistant did to look
    Given the assistant says:
      """
      Is it a monthly or a yearly rule?
      I looked at the scenarios.
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "look-first" is broken

  Scenario: A pack file name in the folder for discovery is not a break of plain words
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      The pack is saved as docs/discovery/2026-11-12-members.md.
      ## Readiness
      Ready for design.
      """
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: The story text reaches the assistant without carriage returns
    Given the fixture text files of a copy of the harness have Windows line endings
    And the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    When the harness of the copy plays the conversation
    Then call 1 to the assistant has no carriage return

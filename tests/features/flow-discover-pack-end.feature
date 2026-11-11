@flow-discover
Feature: A discover run ends with a readiness statement

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A last message that says what is still needed
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "pack-end" is held

  Scenario: A last message that says ready for design
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      ## Readiness
      Ready for design.
      """
    When the harness plays the conversation
    Then the rule "pack-end" is held

  Scenario: A last message with no readiness line
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      Here is the pack. Thanks.
      """
    When the harness plays the conversation
    Then the rule "pack-end" is broken

  Scenario: Not ready with no list of what is needed
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      ## Readiness
      Not ready.
      """
    When the harness plays the conversation
    Then the rule "pack-end" is broken

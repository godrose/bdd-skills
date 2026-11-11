@flow-discover
Feature: The first message says what exists before it asks

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A first message that starts with what exists
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "look-first" is held

  Scenario: A question before what exists
    Given the assistant says:
      """
      Is it a monthly or a yearly rule?
      What exists: nothing found.
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "look-first" is broken

  Scenario: A first message that starts with what was found
    Given the assistant says:
      """
      What I found:
      - A nightly check already marks it.
      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "look-first" is held

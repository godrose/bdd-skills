@flow-discover
Feature: Each message asks the product manager one question

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A message with one question
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "one-question" is held

  Scenario: An open-questions list and a readiness block before the one question
    Given the assistant says:
      """
      ## Open questions
      1. Who is an administrator?
      2. Where is that set?

      ## Readiness
      Not ready. Missing: who is an administrator?

      Which one do you want, A or B?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "one-question" is held

  Scenario: Numbered notes for the developer before the one question
    Given the assistant says:
      """
      Notes
      1. How does it know who asks? This is for the developer.
      2. Where are refusals kept? This is for the developer.

      Which file type do you want?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "one-question" is held

  Scenario: Questions under the developer heading do not count
    Given the assistant says:
      """
      What exists: nothing.
      Is it monthly?
      For the developer:
      - Where is the date set?
      - Is there a job?

      Done.
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "one-question" is held

  Scenario: Two plain questions
    Given the assistant says:
      """
      What exists: nothing.
      Is it monthly?
      Is it yearly?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "one-question" is broken

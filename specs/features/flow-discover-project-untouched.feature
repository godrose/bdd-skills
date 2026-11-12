@flow-discover
Feature: A discover run changes nothing but its pack folder

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A new file outside the pack folder
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    And the assistant writes "src/new.txt" while it says message 1
    When the harness plays the conversation
    Then the rule "project-untouched" is broken
    And the detail of the rules mentions "src/new.txt"

  Scenario: A file in the pack folder
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    And the assistant writes "docs/discovery/pack.md" while it says message 1
    When the harness plays the conversation
    Then the rule "project-untouched" is held

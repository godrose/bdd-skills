@flow-deliver
Feature: A deliver run asks twice for approval and writes no feature file before the second

  The flow harness plays /bdd:deliver with a fake claude and a fake npm. Unless a scenario says
  otherwise, the product manager replies "Approved" to the first two messages.
  Decision (2026-11-11): The scenarios run the real harness against the fakes of tests/fixtures. Why: the old bash file did, and it needs no login and no network.

  Scenario: A feature file written after two approvals
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "features/late.feature" while it says message 3
    When the harness plays the conversation
    Then the rule "no-feature-before-go-ahead" is held

  Scenario: A feature file written after one approval
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "features/early.feature" while it says message 2
    When the harness plays the conversation
    Then the rule "no-feature-before-go-ahead" is broken
    And the detail of the rules mentions "features/early.feature"

  Scenario: A go-ahead counts as the second approval
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the product manager replies to message 2 with "Fix the wording. Then yes, go ahead."
    And the assistant writes "features/late.feature" while it says message 3
    When the harness plays the conversation
    Then the rule "no-feature-before-go-ahead" is held

  Scenario: A reply that is not an approval
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the product manager replies to message 2 with "Hmm, not sure yet."
    And the assistant writes "features/late.feature" while it says message 3
    When the harness plays the conversation
    Then the rule "no-feature-before-go-ahead" is broken

  Scenario: Two messages that ask for approval
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "approval-asked-once" is held

  Scenario: A third message that asks for approval
    Given the assistant says the checklist and then the scenarios
    And the assistant asks for approval once more
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "approval-asked-once" is broken

@flow-deliver
Feature: The report is in plain words, and only the allowed files change

  Decision (2026-11-11): Look-first is counted here and pack-end is not. Why: deliver has no readiness line. The shared rules are the ones the discover harness counts.
  Decision (2026-11-11): There is no one-question case for deliver. Why: the old file had none, and a migration adds no checks.

  Scenario: A developer line is not a break of plain words
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the parked report
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: A developer note that names a file is not a break
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: A late loan shows its days late.

      E1 A late loan shows how many days late it is: passed
      E2 The notice stays in view when the member scrolls: passed

      Regression: 1 earlier scenario still passes.
      Seen: opened the loans page on the same data.

      Developer note: the steps live in steps/loans.steps.js.
      """
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: A path in the plain report is a break
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: the notice in `src/pages/loans.html`.

      E1 A late loan shows how many days late it is: passed
      E2 The notice stays in view when the member scrolls: passed
      """
    When the harness plays the conversation
    Then the rule "plain-words" is broken

  Scenario: Deliver has no readiness rule, and look-first is still counted
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "pack-end" is not counted
    And the rule "look-first" is held

  Scenario: A step file is an allowed change
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "steps/new.steps.js" while it says message 3
    When the harness plays the conversation
    Then the rule "project-untouched" is held

  Scenario: The package file is not an allowed change
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "package.json" while it says message 3
    When the harness plays the conversation
    Then the rule "project-untouched" is broken

  Scenario: The sample data is an allowed change
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the assistant writes "data/loans.json" while it says message 3
    When the harness plays the conversation
    Then the rule "project-untouched" is held

  Scenario: The installed runner is not a change
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "project-untouched" is held

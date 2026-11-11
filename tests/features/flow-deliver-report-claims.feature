@flow-deliver
Feature: The final report is checked against the examples and against the real test output

  Decision (2026-11-11): Never-reported-passed is judged on the test output the harness saved, not on the model's claim. Why: agreed example E7 of the deliver flow pack.

  Scenario: A parked example reported with its section
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the parked report
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "report-shape" is held

  Scenario: A clean report without the section
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "report-shape" is held

  Scenario: A parked example reported without the section
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: A late loan shows its days late.

      E1 A late loan shows how many days late it is: passed
      E2 The notice stays in view when the member scrolls: couldn't be checked - needs a real browser

      Regression: 1 earlier scenario still passes.
      Seen: opened the loans page on the same data.

      """
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "report-shape" is broken

  Scenario: The section is there and nothing was parked
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: A late loan shows its days late.

      E1 A late loan shows how many days late it is: passed
      E2 The notice stays in view when the member scrolls: passed

      Regression: 1 earlier scenario still passes.
      Seen: opened the loans page on the same data.

      Not checked, and what it risks:
      - E1 Something. For the developer: x.
      """
    When the harness plays the conversation
    Then the rule "report-shape" is broken

  Scenario: A report with no line for E2
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: A late loan shows its days late.

      E1 A late loan shows how many days late it is: passed
      """
    When the harness plays the conversation
    Then the rule "report-shape" is broken

  Scenario: Every example passed while a scenario is pending
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "never-reported-passed" is broken

  Scenario: One example parked while a scenario is pending
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the parked report
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "never-reported-passed" is held

  Scenario: Every example passed and every scenario passed
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "never-reported-passed" is held

  Scenario: Every example passed while no scenario ran
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    And the test run has no scenario
    When the harness plays the conversation
    Then the rule "never-reported-passed" is broken

  Scenario: An example listed as not checked and marked passed
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: A late loan shows its days late.

      E1 A late loan shows how many days late it is: passed
      E2 The notice stays in view when the member scrolls: couldn't be checked - needs a real browser
      E3 Two late loans show two notices: passed

      Regression: 1 earlier scenario still passes.
      Seen: the page for E1 only.

      Not checked, and what it risks:
      - E2 Members may miss the notice. For the developer: needs a real browser.
      - E3 was seen only through the scenarios. For the developer: print the page.
      """
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "parked-not-passed" is broken
    And the detail of the rules mentions "E3"

  Scenario: The parked example is not marked passed
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the parked report
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "parked-not-passed" is held

  Scenario: No section, nothing to contradict
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with the clean report
    When the harness plays the conversation
    Then the rule "parked-not-passed" is held

  Scenario: A range of examples covers one that is passed
    Given the assistant says the checklist and then the scenarios
    And the assistant ends with:
      """
      Delivered: x.

      E1 A: couldn't be checked - x
      E2 B: passed

      Not checked, and what it risks:
      - E1-E2 Members may see nothing. For the developer: look.
      """
    And the test run has one pending scenario
    When the harness plays the conversation
    Then the rule "parked-not-passed" is broken

@flow-discover
Feature: The assistant speaks in plain words

  Decision (2026-11-11): The developer-line case is not written again here. Why: the deliver scenario "A developer line is not a break of plain words" checks the same rule and code path.

  Background:
    Given the harness runs discover on fixture "a"

  Scenario: A plain message
    Given the assistant opens with what exists and one question
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: An offer to save the pack in its folder
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      Here is the pack. Save it to `docs/discovery/`?
      ## Readiness
      Ready for `bdd:design`.
      """
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: Literal values the product manager gave
    Given the assistant says:
      """
      The header uses `name`, `email` and `joined`, for example `2026-11-10T17:17:11Z`, in `members.csv`.
      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: The vocabulary check section names code
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      ## Vocabulary check
      - Reused: member, `listMembers`, src/members.js

      ## Readiness
      Ready.
      """
    When the harness plays the conversation
    Then the rule "plain-words" is held

  Scenario: A path in a message
    Given the assistant says:
      """
      What exists: a check in src/loans/overdue.js.
      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is broken

  Scenario: An identifier in backticks
    Given the assistant says:
      """
      What exists: the `OVERDUE_STATUS` is set.
      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is broken

  Scenario: A page file
    Given the assistant says:
      """
      The page loans.html shows it.
      Is that right?
      """
    And the assistant ends with an unfinished readiness block
    When the harness plays the conversation
    Then the rule "plain-words" is broken

  Scenario: Code in the candidate exclusions
    Given the assistant opens with what exists and one question
    And the assistant ends with:
      """
      ## Candidate exclusions
      - Export in `src/members.js` is out.

      ## Readiness
      Ready.
      """
    When the harness plays the conversation
    Then the rule "plain-words" is broken

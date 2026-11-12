@skills-text
Feature: Discover does not stop on a missing config

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): "stop and ask" is checked once. Why: the old file checked the same text twice.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Decision (2026-11-12): A guess comes before the question as a statement, and the message ends on the question. Why: flow runs of deliver showed "My guess: ... Is that right?" after a question, which counts as a second question line. The phrase is checked as policy, since only a flow run can show how the model follows it.

  Scenario: A missing config does not stop discover
    Given the plugin command "discover"
    Then it does not contain "does not exist, say so and stop"

  Scenario: A guess is a statement and the message ends on the one question
    Given the plugin command "discover"
    Then it contains "State a guess as a statement before the question, end the message on the question, and add no closing line that asks for a confirmation."
